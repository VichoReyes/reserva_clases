defmodule ReservaClases.Classes.EventRepeater do
  @moduledoc """
  This module is responsible for repeating events. It runs every 2 hours, but
  can also be called manually to generate repeats for a specific event.
  It's a GenServer to avoid race conditions when generating repeats.
  """

  use GenServer
  alias ReservaClases.Classes.Event
  alias ReservaClases.Repo
  import Ecto.Query, warn: false

  # START CRON BOILERPLATE
  def start_link(_args) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_args) do
    schedule_repeating()
    {:ok, nil}
  end

  defp schedule_repeating() do
    # run automatically every 2 hours
    Process.send_after(self(), :update_repeats, 2 * 60 * 60 * 1000)
  end

  @doc """
  Given an event that should be repeated weekly,
  generate repetitions for the next 3 weeks immediately.
  If you don't call this function, the repetitions will be generated
  anyway, periodically.
  """
  def generate_repeats(event) do
    GenServer.call(__MODULE__, {:generate_repeats, event})
  end

  @doc """
  Given an event with repetitions, delete it, and disable
  the machinery that would normally make it reappear.
  If include_repetitions is true, future repetitions will also be deleted
  (past repetitions are left untouched).
  """
  def detach_and_delete(event, include_repetitions) do
    GenServer.call(__MODULE__, {:detach_and_delete, event, include_repetitions})
  end


  def handle_call({:generate_repeats, event}, _from, _state) do
    generate_checking_date(event)
    {:reply, :ok, nil}
  end

  def handle_call({:detach_and_delete, event, include_repetitions}, _from, _state) do
    result = detach_and_delete_helper(event, include_repetitions)
    {:reply, result, nil}
  end

  defp detach_and_delete_helper(event, include_repetitions) do
    # stop future generation of repetitions
    if event.is_repeat_of do
      {:ok, _} = Repo.get!(Event, event.is_repeat_of)
        |> Event.changeset(%{repeat_weekly: false})
        |> Repo.update()
    end

    # either delete or detach the next one
    case Repo.one(from(e in Event, where: e.is_repeat_of == ^event.id)) do
      nil -> nil
      %Event{} = repetition_event ->
        if include_repetitions do
          detach_and_delete_helper(repetition_event, include_repetitions)
        else
          {:ok, _} = repetition_event
            |> Event.changeset(%{is_repeat_of: nil})
            |> Repo.update()
        end
    end

    # delete the event
    Repo.delete(event)
  end

  def handle_info(:update_repeats, _state) do
    from = Date.utc_today() |> Date.add(-1) |> NaiveDateTime.new!(~T[00:00:00])
    # 8 weeks
    to = Date.utc_today() |> Date.add(56) |> NaiveDateTime.new!(~T[23:59:59])

    from(e in Event,
      where: e.repeat_weekly == true and e.starts_at >= ^from and e.starts_at <= ^to
    )
    |> Repo.all()
    |> Enum.each(&generate_repeats_helper/1)

    schedule_repeating()
    {:noreply, nil}
  end

  defp generate_checking_date(%Event{starts_at: starts_at, repeat_weekly: true} = event) do
    # just in case someone adds an event very far in the past
    from = Date.utc_today() |> Date.add(-366)
    to = Date.utc_today() |> Date.add(56)

    if Date.compare(starts_at, from) != :lt and Date.compare(starts_at, to) != :gt do
      generate_repeats_helper(event)
    end
  end

  defp generate_repeats_helper(event) do
    existing_repeat =
      Repo.exists?(from(e in Event, where: e.is_repeat_of == ^event.id))

    if not existing_repeat do
      {:ok, new_event} =
        %Event{event | id: nil}
        |> Event.changeset(%{
          starts_at: next_week(event.starts_at),
          is_repeat_of: event.id
        })
        |> Repo.insert()

      # mutually recursive call of `generate_checking_date/1`.
      generate_checking_date(new_event)
    end
  end

  defp next_week(datetime) do
    datetime
    |> NaiveDateTime.add(7, :day)
  end
end

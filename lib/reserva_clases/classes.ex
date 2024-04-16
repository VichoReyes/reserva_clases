defmodule ReservaClases.Classes do
  @moduledoc """
  The Classes context.
  """

  import Ecto.Query, warn: false
  import ReservaClases.Calendar
  alias Swoosh.Email
  alias ReservaClases.Repo

  alias ReservaClases.Classes.Event
  alias ReservaClases.Classes.EventRepeater
  alias ReservaClases.Mailer

  @doc """
  Returns a map of lists of events belonging to a week.
  The week is chosen by an offset from the current week

  ## Examples

      iex> list_events()
      %{1: [%Event{}, ...], 3: [%Event{}]}  # 1 means monday, 3 means wednesday, 7 means sunday

  """
  def list_events(weeks_from_today \\ 0) do
    monday =
      DateTime.now!("America/Santiago")
      |> DateTime.to_date()
      |> Date.add(weeks_from_today * 7)
      |> Date.beginning_of_week()

    sunday = Date.add(monday, 6)
    # datetimes in DB are naive, referring to santiago time
    monday_start = NaiveDateTime.new!(monday, ~T[00:00:00])
    sunday_end = NaiveDateTime.new!(sunday, ~T[23:59:59])

    from(e in Event,
      left_join: r in assoc(e, :reservations),
      where: e.starts_at >= ^monday_start and e.starts_at <= ^sunday_end,
      group_by: e.id,
      select: {e, count(r.id)},
      order_by: [asc: e.starts_at]
    )
    |> Repo.all()
    |> Enum.map(fn {e, count} -> Map.put(e, :reservations_count, count) end)
    |> Enum.group_by(fn e -> Date.day_of_week(e.starts_at) end)
  end

  @doc """
  Inverse operation to the one done by list_events to filter events.
  That is to say, given a date time, return the offset of the week it
  belongs to.
  """
  def week_offset(%NaiveDateTime{} = datetime) do
    current_monday =
      DateTime.now!("America/Santiago")
      |> DateTime.to_date()
      |> Date.beginning_of_week()

    Date.diff(datetime, current_monday)
    |> Integer.floor_div(7)
  end

  @doc """
  Gets a single event.

  Raises `Ecto.NoResultsError` if the Event does not exist.

  ## Examples

      iex> get_event!(123)
      %Event{}

      iex> get_event!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event!(id, preloads \\ []) do
    Event
    |> Repo.get!(id)
    |> Repo.preload(preloads)
  end

  @doc """
  Creates a event.

  ## Examples

      iex> create_event(%{field: value})
      {:ok, %Event{}}

      iex> create_event(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_event(attrs \\ %{}) do
    changeset =
      %Event{}
      |> Event.changeset(attrs)

    case Repo.insert(changeset) do
      {:ok, event} ->
        # if the event is repeated weekly, generate repetitions
        if event.repeat_weekly do
          EventRepeater.generate_repeats(event)
        end

        {:ok, event}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a event.

  ## Examples

      iex> update_event(event, %{field: new_value})
      {:ok, %Event{}}

      iex> update_event(event, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an event.

  ## Examples

      iex> delete_event(event)
      {:ok, %Event{}}

      iex> delete_event(event)
      {:error, %Ecto.Changeset{}}

  """
  def delete_event(event, on_repetitions \\ :keep_repetitions)

  def delete_event(%Event{repeat_weekly: false, is_repeat_of: nil} = event, _) do
    Repo.delete(event)
  end

  def delete_event(%Event{} = event, :delete_repetitions) do
    EventRepeater.detach_and_delete(event, true)
  end

  def delete_event(%Event{} = event, :keep_repetitions) do
    EventRepeater.detach_and_delete(event, false)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event changes.

  ## Examples

      iex> change_event(event)
      %Ecto.Changeset{data: %Event{}}

  """
  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end

  alias ReservaClases.Classes.Reservation

  @doc """
  Returns the list of reservations.

  ## Examples

      iex> list_reservations()
      [%Reservation{}, ...]

  """
  def list_reservations do
    Repo.all(Reservation)
  end

  @doc """
  Gets a single reservation.

  Raises `Ecto.NoResultsError` if the Reservation does not exist.

  ## Examples

      iex> get_reservation!(123)
      %Reservation{}

      iex> get_reservation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_reservation!(id), do: Repo.get!(Reservation, id)

  @doc """
  Creates a reservation.

  ## Examples

      iex> create_reservation(%{field: value}, event.id)
      {:ok, %Reservation{}}

      iex> create_reservation(%{field: bad_value}, event.id)
      {:error, %Ecto.Changeset{}}

  """
  def create_reservation(attrs \\ %{}, event_id) do
    with(
      event = get_event!(event_id, [:reservations]),
      :ok <- ensure_event_accepts_reservations(event),
      {:ok, reservation} <- %Reservation{event_id: event_id}
        |> Reservation.changeset(attrs)
        |> Repo.insert()
    ) do
      send_confirmation_email(reservation, event)
      {:ok, reservation}
    end
  end

  defp send_confirmation_email(%Reservation{} = reservation, event) do
    token = Mailer.GmailToken.get_token()
    Email.new()
      |> Email.to({reservation.full_name, reservation.email})
      |> Email.from({"Boulder DAV", "boulder@dav.cl"})
      |> Email.subject("Reserva realizada")
      |> confirmation_email_contents(reservation, event)
      |> Mailer.deliver!(access_token: token)
  end

  defp confirmation_email_contents(email, reservation, event) do
    Email.text_body(
      email,
      """
      Hola #{reservation.full_name},

      Tu reserva a "#{event.title}" fue realizada.

      Recuerda venir el #{strftime(event.starts_at, "%d de %B a las %H:%M")}.

      #{event.description}

      Si quieres cancelar tu reserva, avisar a administrador@dav.cl

      Saludos
      """
    )
  end

  @doc """
  Returns {true, nil} if the event accepts reservations.
  returns {false, reason} otherwise.
  """
  def event_accepts_reservations(event) do
    now_in_stgo =
      DateTime.now!("America/Santiago")
      |> DateTime.to_naive()

    earlier_limit =
      event.starts_at
      |> NaiveDateTime.add(-8, :day)
      |> NaiveDateTime.beginning_of_day()

    late_limit =
      event.starts_at
      |> NaiveDateTime.add(30, :minute)

    cond do
      event.total_vacancies == 0 ->
        {false, "Esta clase no acepta reservas por esta plataforma"}

      NaiveDateTime.before?(now_in_stgo, earlier_limit) ->
        {false, "Se podrá reservar desde el #{strftime(earlier_limit, "%d de %B")}"}

      NaiveDateTime.before?(late_limit, now_in_stgo) ->
        {false, "Ya es muy tarde para reservar"}

      length(event.reservations) >= event.total_vacancies ->
        {false, "Esta clase ya está llena"}

      true ->
        {true, nil}
    end
  end

  defp ensure_event_accepts_reservations(event) do
    case event_accepts_reservations(event) do
      {true, _} -> :ok
      {false, reason} -> {:error, reason}
    end
  end

  @doc """
  Updates a reservation.

  ## Examples

      iex> update_reservation(reservation, %{field: new_value})
      {:ok, %Reservation{}}

      iex> update_reservation(reservation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_reservation(%Reservation{} = reservation, attrs) do
    reservation
    |> Reservation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a reservation.

  ## Examples

      iex> delete_reservation(reservation)
      {:ok, %Reservation{}}

      iex> delete_reservation(reservation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_reservation(%Reservation{} = reservation) do
    Repo.delete(reservation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking reservation changes.

  ## Examples

      iex> change_reservation(reservation)
      %Ecto.Changeset{data: %Reservation{}}

  """
  def change_reservation(%Reservation{} = reservation, attrs \\ %{}) do
    Reservation.changeset(reservation, attrs)
  end
end

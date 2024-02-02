defmodule ReservaClases.Classes do
  @moduledoc """
  The Classes context.
  """

  import Ecto.Query, warn: false
  alias ReservaClases.Repo

  alias ReservaClases.Classes.Event

  @doc """
  Returns a map of lists of events belonging to a week.
  The week is chosen by an offset from the current week

  ## Examples

      iex> list_events()
      %{1: [%Event{}, ...], 3: [%Event{}]}  # 1 means monday, 3 means wednesday, 7 means sunday

  """
  def list_events(weeks_from_today \\ 0) do
    monday = DateTime.now!("America/Santiago")
    |> DateTime.to_date()
    |> Date.add(weeks_from_today * 7)
    |> Date.beginning_of_week()
    sunday = Date.add(monday, 6)
    # datetimes in DB are naive, referring to santiago time
    monday_start = NaiveDateTime.new!(monday, ~T[00:00:00])
    sunday_end = NaiveDateTime.new!(sunday, ~T[23:59:59])
    from(e in Event, where: e.starts_at >= ^monday_start and e.starts_at <= ^sunday_end)
    |> Repo.all()
    |> Enum.group_by(fn e -> Date.day_of_week(e.starts_at) end)
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
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
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
  Deletes a event.

  ## Examples

      iex> delete_event(event)
      {:ok, %Event{}}

      iex> delete_event(event)
      {:error, %Ecto.Changeset{}}

  """
  def delete_event(%Event{} = event) do
    Repo.delete(event)
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
    case get_event_with_reservations_count(event_id) do
      nil ->
        {:error, "Clase inválida"}
      %{event: %Event{total_vacancies: 0}} ->
        {:error, "Esta clase no acepta reservas por esta plataforma"}
      %{event: event, reservations_count: current_count} ->
        if current_count >= event.total_vacancies do
          {:error, "Esta clase ya está llena"}
        else
          %Reservation{event_id: event_id}
          |> Reservation.changeset(attrs)
          |> Repo.insert()
        end
    end
  end

  def get_event_with_reservations_count(event_id) do
    from(e in Event,
      left_join: r in Reservation, on: r.event_id == e.id,
      where: e.id == ^event_id,
      select: %{event: e, reservations_count: count(r.id)},
      group_by: e.id
    )
    |> Repo.one()
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

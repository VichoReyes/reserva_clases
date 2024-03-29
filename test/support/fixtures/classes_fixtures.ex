defmodule ReservaClases.ClassesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ReservaClases.Classes` context.
  """

  @doc """
  Generate a event.
  """
  def event_fixture(attrs \\ %{}) do
    start_time = DateTime.now!("America/Santiago") |> DateTime.to_naive()
    {:ok, event} =
      attrs
      |> Enum.into(%{
        description: "some description",
        starts_at: start_time,
        title: "some title",
        total_vacancies: 42
      })
      |> ReservaClases.Classes.create_event()

    event
  end

  @doc """
  Generate a reservation.
  """
  def reservation_fixture(attrs \\ %{}) do
    {:ok, reservation} =
      attrs
      |> Enum.into(%{
        email: "some@email",
        full_name: "some full_name",
        is_member: true,
      })
      |> ReservaClases.Classes.create_reservation(event_fixture().id)

    reservation
  end
end

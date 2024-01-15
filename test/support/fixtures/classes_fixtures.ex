defmodule ReservaClases.ClassesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ReservaClases.Classes` context.
  """

  @doc """
  Generate a event.
  """
  def event_fixture(attrs \\ %{}) do
    {:ok, event} =
      attrs
      |> Enum.into(%{
        description: "some description",
        starts_at: ~N[2024-01-14 21:16:00],
        title: "some title",
        total_vacancies: 42
      })
      |> ReservaClases.Classes.create_event()

    event
  end
end

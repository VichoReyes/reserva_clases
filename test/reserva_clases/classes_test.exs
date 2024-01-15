defmodule ReservaClases.ClassesTest do
  use ReservaClases.DataCase

  alias ReservaClases.Classes

  describe "events" do
    alias ReservaClases.Classes.Event

    import ReservaClases.ClassesFixtures

    @invalid_attrs %{description: nil, title: nil, starts_at: nil, total_vacancies: nil}

    test "list_events/0 returns all events" do
      event = event_fixture()
      assert Classes.list_events() == [event]
    end

    test "get_event!/1 returns the event with given id" do
      event = event_fixture()
      assert Classes.get_event!(event.id) == event
    end

    test "create_event/1 with valid data creates a event" do
      valid_attrs = %{description: "some description", title: "some title", starts_at: ~N[2024-01-14 21:16:00], total_vacancies: 42}

      assert {:ok, %Event{} = event} = Classes.create_event(valid_attrs)
      assert event.description == "some description"
      assert event.title == "some title"
      assert event.starts_at == ~N[2024-01-14 21:16:00]
      assert event.total_vacancies == 42
    end

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Classes.create_event(@invalid_attrs)
    end

    test "update_event/2 with valid data updates the event" do
      event = event_fixture()
      update_attrs = %{description: "some updated description", title: "some updated title", starts_at: ~N[2024-01-15 21:16:00], total_vacancies: 43}

      assert {:ok, %Event{} = event} = Classes.update_event(event, update_attrs)
      assert event.description == "some updated description"
      assert event.title == "some updated title"
      assert event.starts_at == ~N[2024-01-15 21:16:00]
      assert event.total_vacancies == 43
    end

    test "update_event/2 with invalid data returns error changeset" do
      event = event_fixture()
      assert {:error, %Ecto.Changeset{}} = Classes.update_event(event, @invalid_attrs)
      assert event == Classes.get_event!(event.id)
    end

    test "delete_event/1 deletes the event" do
      event = event_fixture()
      assert {:ok, %Event{}} = Classes.delete_event(event)
      assert_raise Ecto.NoResultsError, fn -> Classes.get_event!(event.id) end
    end

    test "change_event/1 returns a event changeset" do
      event = event_fixture()
      assert %Ecto.Changeset{} = Classes.change_event(event)
    end
  end
end

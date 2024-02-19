defmodule ReservaClases.ClassesTest do
  use ReservaClases.DataCase

  alias ReservaClases.Classes

  describe "events" do
    alias ReservaClases.Classes.Event

    import ReservaClases.ClassesFixtures

    @invalid_attrs %{description: nil, title: nil, starts_at: nil, total_vacancies: nil}

    test "list_events/0 returns events of week" do
      event = event_fixture()
      _past_event = event_fixture(starts_at: ~N[2010-01-01T10:00:00])
      events = Classes.list_events()
      |> Map.values()
      assert events == [[Map.put(event, :reservations_count, 0)]]
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

  describe "reservations" do
    alias ReservaClases.Classes.Reservation

    import ReservaClases.ClassesFixtures

    @invalid_attrs %{is_member: nil, full_name: nil, email: nil}

    test "list_reservations/0 returns all reservations" do
      reservation = reservation_fixture()
      assert Classes.list_reservations() == [reservation]
    end

    test "get_reservation!/1 returns the reservation with given id" do
      reservation = reservation_fixture()
      assert Classes.get_reservation!(reservation.id) == reservation
    end

    test "create_reservation/2 with valid data creates a reservation" do
      event = event_fixture()
      valid_attrs = %{is_member: true, full_name: "some full_name", email: "some@email.com"}

      assert {:ok, %Reservation{} = reservation} = Classes.create_reservation(valid_attrs, event.id)
      assert reservation.is_member == true
      assert reservation.full_name == "some full_name"
      assert reservation.email == "some@email.com"
      assert reservation.event_id == event.id
    end

    test "create_reservation/2 errors with invalid event_id" do
      assert {:error, msg} = Classes.create_reservation(@invalid_attrs, 123456)
      assert msg =~ "Clase inválida"
    end

    test "create_reservation/2 doesn't allow creating on full events" do
      valid_attrs = %{description: "some description", title: "some title", starts_at: ~N[2024-01-14 21:16:00], total_vacancies: 42}
      event = event_fixture(%{total_vacancies: 0})
      assert {:error, msg} = Classes.create_reservation(valid_attrs, event.id)
      assert is_binary(msg)
    end

    test "create_reservation/2 with invalid data returns error changeset" do
      event = event_fixture()
      assert {:error, %Ecto.Changeset{}} = Classes.create_reservation(@invalid_attrs, event.id)
    end

    test "update_reservation/2 with valid data updates the reservation" do
      reservation = reservation_fixture()
      update_attrs = %{is_member: false, full_name: "some updated full_name", email: "some_updated@email"}

      assert {:ok, %Reservation{} = reservation} = Classes.update_reservation(reservation, update_attrs)
      assert reservation.is_member == false
      assert reservation.full_name == "some updated full_name"
      assert reservation.email == "some_updated@email"
    end

    test "update_reservation/2 with invalid data returns error changeset" do
      reservation = reservation_fixture()
      assert {:error, %Ecto.Changeset{}} = Classes.update_reservation(reservation, @invalid_attrs)
      assert reservation == Classes.get_reservation!(reservation.id)
    end

    test "delete_reservation/1 deletes the reservation" do
      reservation = reservation_fixture()
      assert {:ok, %Reservation{}} = Classes.delete_reservation(reservation)
      assert_raise Ecto.NoResultsError, fn -> Classes.get_reservation!(reservation.id) end
    end

    test "change_reservation/1 returns a reservation changeset" do
      reservation = reservation_fixture()
      assert %Ecto.Changeset{} = Classes.change_reservation(reservation)
    end
  end
end

defmodule ReservaClases.ClassesTest do
  alias ReservaClases.Classes.EventRepeater
  use ReservaClases.DataCase

  alias ReservaClases.Classes

  describe "events" do
    alias ReservaClases.Classes.Event

    import ReservaClases.ClassesFixtures

    @invalid_attrs %{description: nil, title: nil, starts_at: nil, total_vacancies: nil}

    test "list_events/0 returns events of week" do
      event = event_fixture()
      _past_event = event_fixture(starts_at: ~N[2010-01-01T10:00:00])
      events =
        Classes.list_events()
        |> Map.values()
      assert events == [[Map.put(event, :reservations_count, 0)]]
    end

    test "get_event!/1 returns the event with given id" do
      event = event_fixture()
      assert Classes.get_event!(event.id) == event
    end

    test "create_event/1 with valid data creates a event" do
      valid_attrs = %{
        description: "some description",
        title: "some title",
        starts_at: ~N[2024-01-14 21:16:00],
        total_vacancies: 42
      }

      assert {:ok, %Event{} = event} = Classes.create_event(valid_attrs)
      assert event.description == "some description"
      assert event.title == "some title"
      assert event.starts_at == ~N[2024-01-14 21:16:00]
      assert event.total_vacancies == 42
    end

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Classes.create_event(@invalid_attrs)
    end

    test "create_event/1 with repeat_weekly creates at least three events" do
      first_event = event_fixture(%{repeat_weekly: true})
      assert first_event.repeat_weekly == true
      assert first_event.is_repeat_of == nil

      second_event = from(e in Event, where: e.is_repeat_of == ^first_event.id) |> Repo.one!()
      assert second_event.repeat_weekly == true
      assert second_event.is_repeat_of == first_event.id
      assert second_event.starts_at == NaiveDateTime.add(first_event.starts_at, 7, :day)

      third_event = from(e in Event, where: e.is_repeat_of == ^second_event.id) |> Repo.one!()
      assert third_event.repeat_weekly == true
      assert third_event.is_repeat_of == second_event.id
      assert third_event.starts_at == NaiveDateTime.add(second_event.starts_at, 7, :day)
    end

    test "update_event/2 with valid data updates the event" do
      event = event_fixture()

      update_attrs = %{
        description: "some updated description",
        title: "some updated title",
        starts_at: ~N[2024-01-15 21:16:00],
        total_vacancies: 43
      }

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

    test "delete_event/1 with :delete_repetitions deletes all repetitions" do
      event = event_fixture(%{repeat_weekly: true})
      assert {:ok, _} = Classes.delete_event(event, :delete_repetitions)
      assert Repo.aggregate(Event, :count) == 0
    end

    test "delete_event/1 with :keep_repetitions deletes the event but keeps repetitions" do
      event = event_fixture(%{repeat_weekly: true})
      assert {:ok, _} = Classes.delete_event(event, :keep_repetitions)
      assert_raise Ecto.NoResultsError, fn -> Classes.get_event!(event.id) end
      assert Repo.aggregate(Event, :count) > 0
    end

    test "delete_event/1 on a repetition stays deleted (:delete_repetitions case)" do
      event = event_fixture(%{repeat_weekly: true})
      first_repeat = from(e in Event, where: e.is_repeat_of == ^event.id) |> Repo.one!()
      {:ok, _} = Classes.delete_event(first_repeat, :delete_repetitions)
      assert Repo.aggregate(Event, :count) == 1
      {:noreply, nil} = EventRepeater.handle_info(:update_repeats, nil)
      assert Repo.aggregate(Event, :count) == 1
    end

    test "delete_event/1 on a repetition stays deleted (:keep_repetitions case)" do
      event = event_fixture(%{repeat_weekly: true})
      first_repeat = from(e in Event, where: e.is_repeat_of == ^event.id) |> Repo.one!()
      total_num_events = Repo.aggregate(Event, :count)
      {:ok, _} = Classes.delete_event(first_repeat, :keep_repetitions)
      assert Repo.aggregate(Event, :count) == total_num_events - 1
      {:noreply, nil} = EventRepeater.handle_info(:update_repeats, nil)
      assert Repo.aggregate(Event, :count) == total_num_events - 1
    end

    test "delete_event/1 on a repetition stays deleted (third, specific case)" do
      event = event_fixture(%{repeat_weekly: true})
      first_repeat = from(e in Event, where: e.is_repeat_of == ^event.id) |> Repo.one!()
      second_repeat = from(e in Event, where: e.is_repeat_of == ^first_repeat.id) |> Repo.one!()
      total_num_events = Repo.aggregate(Event, :count)
      {:ok, _} = Classes.delete_event(second_repeat, :keep_repetitions)
      assert Repo.aggregate(Event, :count) == total_num_events - 1
      {:ok, _} = Classes.delete_event(Classes.get_event!(first_repeat.id))
      {:noreply, nil} = EventRepeater.handle_info(:update_repeats, nil)
      assert Repo.aggregate(Event, :count) == total_num_events - 2
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
    @valid_attrs %{is_member: true, full_name: "some full_name", email: "some@email.com"}

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

      assert {:ok, %Reservation{} = reservation} =
               Classes.create_reservation(@valid_attrs, event.id)

      assert reservation.is_member == true
      assert reservation.full_name == "some full_name"
      assert reservation.email == "some@email.com"
      assert reservation.event_id == event.id
    end

    test "create_reservation/2 doesn't allow creating on full events" do
      event = event_fixture(%{total_vacancies: 1})
      assert {:ok, _} = Classes.create_reservation(@valid_attrs, event.id)

      assert {:error, "Esta clase ya está llena"} =
               Classes.create_reservation(%{@valid_attrs | email: "other@email.com"}, event.id)
    end

    test "create_reservation/2 allows two reservations with same email" do
      event = event_fixture(%{total_vacancies: 5})
      assert {:ok, res1} = Classes.create_reservation(@valid_attrs, event.id)
      assert {:ok, res2} = Classes.create_reservation(@valid_attrs, event.id)

      assert res1.id != res2.id
    end

    test "create_reservation/2 doesn't allow reservations too far into the future" do
      future_date = NaiveDateTime.utc_now() |> NaiveDateTime.add(30, :day)
      event = event_fixture(%{starts_at: future_date})

      assert {:error, message} =
               Classes.create_reservation(@valid_attrs, event.id)
      assert message =~ ~r/se podrá reservar desde el [0-9]+ de/i
    end

    test "create_reservation/2 doesn't allow reserving too late" do
      past_date = NaiveDateTime.utc_now() |> NaiveDateTime.add(-1, :day)
      event = event_fixture(%{starts_at: past_date})

      assert {:error, message} =
                 Classes.create_reservation(@valid_attrs, event.id)
      assert message =~ ~r/es muy tarde para reservar/i
    end

    test "create_reservation/2 with invalid data returns error changeset" do
      event = event_fixture()
      assert {:error, %Ecto.Changeset{}} = Classes.create_reservation(@invalid_attrs, event.id)
    end

    test "update_reservation/2 with valid data updates the reservation" do
      reservation = reservation_fixture()

      update_attrs = %{
        is_member: false,
        full_name: "some updated full_name",
        email: "some_updated@email"
      }

      assert {:ok, %Reservation{} = reservation} =
               Classes.update_reservation(reservation, update_attrs)

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

    test "create_reservation/2 returns {:ok, reservation, :email_failed} when email sending fails" do
      event = event_fixture()

      # Create a failing email sender function
      failing_email_sender = fn _reservation, _event ->
        {:error, "Email service unavailable"}
      end

      # Call create_reservation with the failing email sender
      assert {:ok, %Reservation{} = reservation, :email_failed} =
               Classes.create_reservation(
                 @valid_attrs,
                 event.id,
                 email_sender: failing_email_sender
               )

      # Verify reservation was still created despite email failure
      assert reservation.email == "some@email.com"
      assert reservation.full_name == "some full_name"

      # Verify reservation exists in database
      assert Classes.get_reservation!(reservation.id)
    end
  end
end

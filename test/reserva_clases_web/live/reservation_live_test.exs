defmodule ReservaClasesWeb.ReservationLiveTest do
  use ReservaClasesWeb.ConnCase

  import Phoenix.LiveViewTest
  import ReservaClases.ClassesFixtures

  # @create_attrs %{is_member: true, full_name: "some full_name", email: "some email"}
  @update_attrs %{is_member: false, full_name: "some updated full_name", email: "someupdated@email.com"}
  @invalid_attrs %{is_member: false, full_name: nil, email: nil}

  defp create_reservation(_) do
    reservation = reservation_fixture()
    %{reservation: reservation}
  end

  describe "Index" do
    setup [:create_reservation, :register_and_log_in_administrator]

    test "lists all reservations", %{conn: conn, reservation: reservation} do
      {:ok, _index_live, html} = live(conn, ~p"/reservations")

      assert html =~ "Listing Reservations"
      assert html =~ reservation.full_name
    end

    # No se puede crear una reserva sin un evento asociado
    # Pero se guarda este código para cuando la creación de reservas sea posible
    # test "saves new reservation", %{conn: conn} do
    #   {:ok, index_live, _html} = live(conn, ~p"/reservations")

    #   assert index_live |> element("a", "New Reservation") |> render_click() =~
    #            "New Reservation"

    #   assert_patch(index_live, ~p"/reservations/new")

    #   assert index_live
    #          |> form("#reservation-form", reservation: @invalid_attrs)
    #          |> render_change() =~ "can&#39;t be blank"

    #   assert index_live
    #          |> form("#reservation-form", reservation: @create_attrs)
    #          |> render_submit()

    #   assert_patch(index_live, ~p"/reservations")

    #   html = render(index_live)
    #   assert html =~ "Reservation created successfully"
    #   assert html =~ "some full_name"
    # end

    test "updates reservation in listing", %{conn: conn, reservation: reservation} do
      {:ok, index_live, _html} = live(conn, ~p"/reservations")

      assert index_live |> element("#reservations-#{reservation.id} a", "Edit") |> render_click() =~
               "Edit Reservation"

      assert_patch(index_live, ~p"/reservations/#{reservation}/edit")

      assert index_live
             |> form("#reservation-form", reservation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#reservation-form", reservation: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/reservations")

      html = render(index_live)
      assert html =~ "Reservation updated successfully"
      assert html =~ "some updated full_name"
    end

    test "deletes reservation in listing", %{conn: conn, reservation: reservation} do
      {:ok, index_live, _html} = live(conn, ~p"/reservations")

      assert index_live |> element("#reservations-#{reservation.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#reservations-#{reservation.id}")
    end
  end
end

defmodule ReservaClasesWeb.EventLiveTest do
  use ReservaClasesWeb.ConnCase

  import Phoenix.LiveViewTest
  import ReservaClases.ClassesFixtures

  @now_in_santiago DateTime.now!("America/Santiago") |> DateTime.to_naive()
  @create_attrs %{description: "some new description", title: "some new title", starts_at: @now_in_santiago, total_vacancies: 42}
  @update_attrs %{description: "some updated description", title: "some updated title", starts_at: @now_in_santiago, total_vacancies: 43}
  @invalid_attrs %{description: nil, title: nil, starts_at: nil, total_vacancies: nil}

  defp create_event(_) do
    event = event_fixture()
    %{event: event}
  end

  describe "Index" do
    setup [:create_event, :register_and_log_in_administrator]

    test "lists all events", %{conn: conn, event: event} do
      {:ok, _index_live, html} = live(conn, ~p"/events")

      assert html =~ event.title
    end

    test "adapts title", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/events")
      assert html =~ "Clases de esta semana"

      {:ok, _index_live, html} = live(conn, ~p"/events?week=1")
      assert html =~ "Clases de la próxima semana"
    end

    test "saves new event", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/events")

      assert index_live |> element("a", "Nueva clase") |> render_click() =~
               "Nueva clase"

      assert_patch(index_live, ~p"/events/new")

      assert index_live
             |> form("#event-form", event: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#event-form", event: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/events?week=0")

      html = render(index_live)
      assert html =~ "Clase creada"
      assert html =~ "some new title"
    end

    test "updates event in listing", %{conn: conn, event: event} do
      {:ok, index_live, _html} = live(conn, ~p"/events")

      assert index_live |> element("#events-#{event.id} a", "Edit") |> render_click() =~
               "Editar #{event.title}"

      assert_patch(index_live, ~p"/events/#{event}/edit?week=0")

      assert index_live
             |> form("#event-form", event: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#event-form", event: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/events?week=0")

      html = render(index_live)
      assert html =~ "Clase modificada"
      assert html =~ "some updated title"
    end

    test "deletes event in listing", %{conn: conn, event: event} do
      {:ok, index_live, _html} = live(conn, ~p"/events")

      assert index_live |> element("#events-#{event.id} a", "Eliminar") |> render_click()
      refute has_element?(index_live, "#events-#{event.id}")
    end
  end

  describe "Show" do
    setup [:create_event, :register_and_log_in_administrator]

    test "displays event", %{conn: conn, event: event} do
      {:ok, _show_live, html} = live(conn, ~p"/events/#{event}")

      assert html =~ event.title
      assert html =~ event.description
    end

    test "updates event within modal", %{conn: conn, event: event} do
      {:ok, show_live, _html} = live(conn, ~p"/events/#{event}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Editando #{event.title}"

      assert_patch(show_live, ~p"/events/#{event}/show/edit")

      assert show_live
             |> form("#event-form", event: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#event-form", event: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/events/#{event}")

      html = render(show_live)
      assert html =~ "Clase modificada"
      assert html =~ "some updated title"
    end
  end
end

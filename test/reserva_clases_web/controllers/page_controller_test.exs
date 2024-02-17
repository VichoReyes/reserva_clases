defmodule ReservaClasesWeb.PageControllerTest do
  use ReservaClasesWeb.ConnCase
  setup [:register_and_log_in_administrator]

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Sitio de administración de reservas"
  end
end

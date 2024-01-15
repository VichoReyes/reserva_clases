defmodule ReservaClasesWeb.AdministratorSessionControllerTest do
  use ReservaClasesWeb.ConnCase, async: true

  import ReservaClases.AccountsFixtures

  setup do
    %{administrator: administrator_fixture()}
  end

  describe "POST /administrators/log_in" do
    test "logs the administrator in", %{conn: conn, administrator: administrator} do
      conn =
        post(conn, ~p"/administrators/log_in", %{
          "administrator" => %{"email" => administrator.email, "password" => valid_administrator_password()}
        })

      assert get_session(conn, :administrator_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ administrator.email
      assert response =~ ~p"/administrators/settings"
      assert response =~ ~p"/administrators/log_out"
    end

    test "logs the administrator in with remember me", %{conn: conn, administrator: administrator} do
      conn =
        post(conn, ~p"/administrators/log_in", %{
          "administrator" => %{
            "email" => administrator.email,
            "password" => valid_administrator_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_reserva_clases_web_administrator_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the administrator in with return to", %{conn: conn, administrator: administrator} do
      conn =
        conn
        |> init_test_session(administrator_return_to: "/foo/bar")
        |> post(~p"/administrators/log_in", %{
          "administrator" => %{
            "email" => administrator.email,
            "password" => valid_administrator_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "login following registration", %{conn: conn, administrator: administrator} do
      conn =
        conn
        |> post(~p"/administrators/log_in", %{
          "_action" => "registered",
          "administrator" => %{
            "email" => administrator.email,
            "password" => valid_administrator_password()
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "login following password update", %{conn: conn, administrator: administrator} do
      conn =
        conn
        |> post(~p"/administrators/log_in", %{
          "_action" => "password_updated",
          "administrator" => %{
            "email" => administrator.email,
            "password" => valid_administrator_password()
          }
        })

      assert redirected_to(conn) == ~p"/administrators/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password updated successfully"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/administrators/log_in", %{
          "administrator" => %{"email" => "invalid@email.com", "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/administrators/log_in"
    end
  end

  describe "DELETE /administrators/log_out" do
    test "logs the administrator out", %{conn: conn, administrator: administrator} do
      conn = conn |> log_in_administrator(administrator) |> delete(~p"/administrators/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :administrator_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the administrator is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/administrators/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :administrator_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end

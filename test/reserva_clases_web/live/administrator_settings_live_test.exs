defmodule ReservaClasesWeb.AdministratorSettingsLiveTest do
  use ReservaClasesWeb.ConnCase

  alias ReservaClases.Accounts
  import Phoenix.LiveViewTest
  import ReservaClases.AccountsFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_administrator(administrator_fixture())
        |> live(~p"/administrators/settings")

      assert html =~ "Change Email"
      assert html =~ "Change Password"
    end

    test "redirects if administrator is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/administrators/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/administrators/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_administrator_password()
      administrator = administrator_fixture(%{password: password})
      %{conn: log_in_administrator(conn, administrator), administrator: administrator, password: password}
    end

    test "updates the administrator email", %{conn: conn, password: password, administrator: administrator} do
      new_email = unique_administrator_email()

      {:ok, lv, _html} = live(conn, ~p"/administrators/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => password,
          "administrator" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Accounts.get_administrator_by_email(administrator.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/administrators/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "administrator" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, administrator: administrator} do
      {:ok, lv, _html} = live(conn, ~p"/administrators/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => "invalid",
          "administrator" => %{"email" => administrator.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_administrator_password()
      administrator = administrator_fixture(%{password: password})
      %{conn: log_in_administrator(conn, administrator), administrator: administrator, password: password}
    end

    test "updates the administrator password", %{conn: conn, administrator: administrator, password: password} do
      new_password = valid_administrator_password()

      {:ok, lv, _html} = live(conn, ~p"/administrators/settings")

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "administrator" => %{
            "email" => administrator.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/administrators/settings"

      assert get_session(new_password_conn, :administrator_token) != get_session(conn, :administrator_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_administrator_by_email_and_password(administrator.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/administrators/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "administrator" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/administrators/settings")

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "administrator" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      administrator = administrator_fixture()
      email = unique_administrator_email()

      token =
        extract_administrator_token(fn url ->
          Accounts.deliver_administrator_update_email_instructions(%{administrator | email: email}, administrator.email, url)
        end)

      %{conn: log_in_administrator(conn, administrator), token: token, email: email, administrator: administrator}
    end

    test "updates the administrator email once", %{conn: conn, administrator: administrator, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/administrators/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/administrators/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Accounts.get_administrator_by_email(administrator.email)
      assert Accounts.get_administrator_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/administrators/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/administrators/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, administrator: administrator} do
      {:error, redirect} = live(conn, ~p"/administrators/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/administrators/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Accounts.get_administrator_by_email(administrator.email)
    end

    test "redirects if administrator is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/administrators/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/administrators/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end

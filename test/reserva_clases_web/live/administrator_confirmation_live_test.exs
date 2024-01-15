defmodule ReservaClasesWeb.AdministratorConfirmationLiveTest do
  use ReservaClasesWeb.ConnCase

  import Phoenix.LiveViewTest
  import ReservaClases.AccountsFixtures

  alias ReservaClases.Accounts
  alias ReservaClases.Repo

  setup do
    %{administrator: administrator_fixture()}
  end

  describe "Confirm administrator" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/administrators/confirm/some-token")
      assert html =~ "Confirm Account"
    end

    test "confirms the given token once", %{conn: conn, administrator: administrator} do
      token =
        extract_administrator_token(fn url ->
          Accounts.deliver_administrator_confirmation_instructions(administrator, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/administrators/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Administrator confirmed successfully"

      assert Accounts.get_administrator!(administrator.id).confirmed_at
      refute get_session(conn, :administrator_token)
      assert Repo.all(Accounts.AdministratorToken) == []

      # when not logged in
      {:ok, lv, _html} = live(conn, ~p"/administrators/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Administrator confirmation link is invalid or it has expired"

      # when logged in
      conn =
        build_conn()
        |> log_in_administrator(administrator)

      {:ok, lv, _html} = live(conn, ~p"/administrators/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, administrator: administrator} do
      {:ok, lv, _html} = live(conn, ~p"/administrators/confirm/invalid-token")

      {:ok, conn} =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Administrator confirmation link is invalid or it has expired"

      refute Accounts.get_administrator!(administrator.id).confirmed_at
    end
  end
end

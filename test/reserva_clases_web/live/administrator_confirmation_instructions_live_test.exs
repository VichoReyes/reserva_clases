defmodule ReservaClasesWeb.AdministratorConfirmationInstructionsLiveTest do
  use ReservaClasesWeb.ConnCase

  import Phoenix.LiveViewTest
  import ReservaClases.AccountsFixtures

  alias ReservaClases.Accounts
  alias ReservaClases.Repo

  setup do
    %{administrator: administrator_fixture()}
  end

  describe "Resend confirmation" do
    test "renders the resend confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/administrators/confirm")
      assert html =~ "Resend confirmation instructions"
    end

    test "sends a new confirmation token", %{conn: conn, administrator: administrator} do
      {:ok, lv, _html} = live(conn, ~p"/administrators/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", administrator: %{email: administrator.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.get_by!(Accounts.AdministratorToken, administrator_id: administrator.id).context == "confirm"
    end

    test "does not send confirmation token if administrator is confirmed", %{conn: conn, administrator: administrator} do
      Repo.update!(Accounts.Administrator.confirm_changeset(administrator))

      {:ok, lv, _html} = live(conn, ~p"/administrators/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", administrator: %{email: administrator.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      refute Repo.get_by(Accounts.AdministratorToken, administrator_id: administrator.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/administrators/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", administrator: %{email: "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.all(Accounts.AdministratorToken) == []
    end
  end
end

defmodule ReservaClasesWeb.AdministratorSessionController do
  use ReservaClasesWeb, :controller

  alias ReservaClases.Accounts
  alias ReservaClasesWeb.AdministratorAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:administrator_return_to, ~p"/administrators/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"administrator" => administrator_params}, info) do
    %{"email" => email, "password" => password} = administrator_params

    if administrator = Accounts.get_administrator_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> AdministratorAuth.log_in_administrator(administrator, administrator_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/administrators/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> AdministratorAuth.log_out_administrator()
  end
end

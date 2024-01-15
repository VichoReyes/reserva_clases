defmodule ReservaClases.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ReservaClases.Accounts` context.
  """

  def unique_administrator_email, do: "administrator#{System.unique_integer()}@example.com"
  def valid_administrator_password, do: "hello world!"

  def valid_administrator_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_administrator_email(),
      password: valid_administrator_password()
    })
  end

  def administrator_fixture(attrs \\ %{}) do
    {:ok, administrator} =
      attrs
      |> valid_administrator_attributes()
      |> ReservaClases.Accounts.register_administrator()

    administrator
  end

  def extract_administrator_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end

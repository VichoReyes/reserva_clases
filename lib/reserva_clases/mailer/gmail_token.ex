defmodule ReservaClases.Mailer.GmailToken do
  require Logger
  use GenServer

  @token_url "https://oauth2.googleapis.com/token"

  def start_link(_args) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, {nil, ~U[2020-01-01 10:00:00Z]}}
  end

  def get_token() do
    GenServer.call(__MODULE__, :get_token)
  end

  def handle_call(:get_token, _from, {access_token, expiry}) do
    current_time = DateTime.add(DateTime.utc_now(), 1, :minute)

    case DateTime.compare(current_time, expiry) do
      :lt ->
        {:reply, access_token, {access_token, expiry}}

      _ ->
        {new_token, new_expiry} = do_refresh_token()
        {:reply, new_token, {new_token, new_expiry}}
    end
  end

  defp do_refresh_token() do
    if Application.get_env(:reserva_clases, :refresh_gmail) do
      response =
        Req.post!(@token_url,
          form: [
            client_id: get_env!("GOOGLE_CLIENT_ID"),
            client_secret: get_env!("GOOGLE_CLIENT_SECRET"),
            refresh_token: get_env!("GOOGLE_REFRESH_TOKEN"),
            grant_type: "refresh_token"
          ]
        ).body

      %{"access_token" => access_token, "expires_in" => expiry_seconds} = response
      expire_time = DateTime.add(DateTime.utc_now(), expiry_seconds, :second)
      Logger.info("returning real google token")
      {access_token, expire_time}
    else
      expire_time = DateTime.add(DateTime.utc_now(), 3600, :second)
      Logger.info("returning fake google token")
      {"FAKE_GMAIL_ACCESS_TOKEN", expire_time}
    end
  end

  defp get_env!(name) do
    System.get_env(name) || raise "environment variable #{name} missing!"
  end
end

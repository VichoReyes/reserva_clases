defmodule ReservaClases.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ReservaClasesWeb.Telemetry,
      # Start the Ecto repository
      ReservaClases.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: ReservaClases.PubSub},
      # Start Finch
      {Finch, name: ReservaClases.Finch},
      # Start the Endpoint (http/https)
      ReservaClasesWeb.Endpoint,
      # Start a worker by calling: ReservaClases.Worker.start_link(arg)
      # {ReservaClases.Worker, arg}
      ReservaClases.Classes.EventRepeater,
      ReservaClases.Mailer.GmailToken,
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ReservaClases.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ReservaClasesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

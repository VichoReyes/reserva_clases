defmodule ReservaClasesWeb.Router do
  use ReservaClasesWeb, :router

  import ReservaClasesWeb.AdministratorAuth
  import Phoenix.LiveDashboard.Router

  defp allow_dav_iframe(conn, _opts) do
    # permite embedear en un iframe desde el dominio del DAV
    conn
    |> Plug.Conn.put_resp_header("content-security-policy", "frame-ancestors 'self' https://vichoreyes.cl/ https://dav.cl/; frame-src 'self' https://challenges.cloudflare.com; script-src 'self' https://challenges.cloudflare.com")
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ReservaClasesWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :allow_dav_iframe  # TODO: move to a separate pipeline?
    plug :fetch_current_administrator
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ReservaClasesWeb do
    pipe_through [:browser, :require_authenticated_administrator]

    get "/", PageController, :home

    live_session :only_admins,
      on_mount: [{ReservaClasesWeb.AdministratorAuth, :ensure_authenticated}] do
      live "/administrators/settings", AdministratorSettingsLive, :edit
      live "/administrators/settings/confirm_email/:token", AdministratorSettingsLive, :confirm_email

      live "/reservations", ReservationLive.Index, :index
      live "/reservations/:id/edit", ReservationLive.Index, :edit
    end

    live_dashboard "/phoenix_dashboard", metrics: ReservaClasesWeb.Telemetry
  end

  scope "/", ReservaClasesWeb do
    pipe_through :browser

    live_session :unauthenticated,
      on_mount: [{ReservaClasesWeb.AdministratorAuth, :mount_current_administrator}] do

      live "/events/new", EventLive.Index, :new
      live "/events/:id/edit", EventLive.Index, :edit
      live "/events/:id/delete_repeat", EventLive.Index, :delete_repeat
      live "/events/:id/show/edit", EventLive.Show, :edit

      # se pueden crear reservas sin ser administrador, pero montamos el administrador
      # para revisar permisos especiales
      live "/events", EventLive.Index, :index
      live "/events/:id", EventLive.Show, :show
      live "/events/:id/new_reservation", EventLive.Show, :new_reservation
    end

  end

  # Other scopes may use custom stacks.
  # scope "/api", ReservaClasesWeb do
  #   pipe_through :api
  # end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:reserva_clases, :dev_routes) do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", ReservaClasesWeb do
    pipe_through [:browser, :redirect_if_administrator_is_authenticated]

    live_session :redirect_if_administrator_is_authenticated,
      on_mount: [{ReservaClasesWeb.AdministratorAuth, :redirect_if_administrator_is_authenticated}] do
      live "/administrators/log_in", AdministratorLoginLive, :new
      live "/administrators/reset_password", AdministratorForgotPasswordLive, :new
      live "/administrators/reset_password/:token", AdministratorResetPasswordLive, :edit
    end

    post "/administrators/log_in", AdministratorSessionController, :create
  end

  scope "/", ReservaClasesWeb do
    pipe_through [:browser]

    delete "/administrators/log_out", AdministratorSessionController, :delete
  end
end

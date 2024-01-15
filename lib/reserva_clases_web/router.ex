defmodule ReservaClasesWeb.Router do
  use ReservaClasesWeb, :router

  import ReservaClasesWeb.AdministratorAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ReservaClasesWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_administrator
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ReservaClasesWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", ReservaClasesWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:reserva_clases, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ReservaClasesWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", ReservaClasesWeb do
    pipe_through [:browser, :redirect_if_administrator_is_authenticated]

    live_session :redirect_if_administrator_is_authenticated,
      on_mount: [{ReservaClasesWeb.AdministratorAuth, :redirect_if_administrator_is_authenticated}] do
      live "/administrators/register", AdministratorRegistrationLive, :new
      live "/administrators/log_in", AdministratorLoginLive, :new
      live "/administrators/reset_password", AdministratorForgotPasswordLive, :new
      live "/administrators/reset_password/:token", AdministratorResetPasswordLive, :edit
    end

    post "/administrators/log_in", AdministratorSessionController, :create
  end

  scope "/", ReservaClasesWeb do
    pipe_through [:browser, :require_authenticated_administrator]

    live_session :require_authenticated_administrator,
      on_mount: [{ReservaClasesWeb.AdministratorAuth, :ensure_authenticated}] do
      live "/administrators/settings", AdministratorSettingsLive, :edit
      live "/administrators/settings/confirm_email/:token", AdministratorSettingsLive, :confirm_email

      # administración de eventos
      live "/events", EventLive.Index, :index
      live "/events/new", EventLive.Index, :new
      live "/events/:id/edit", EventLive.Index, :edit

      live "/events/:id", EventLive.Show, :show
      live "/events/:id/show/edit", EventLive.Show, :edit
    end
  end

  scope "/", ReservaClasesWeb do
    pipe_through [:browser]

    delete "/administrators/log_out", AdministratorSessionController, :delete

    live_session :current_administrator,
      on_mount: [{ReservaClasesWeb.AdministratorAuth, :mount_current_administrator}] do
      live "/administrators/confirm/:token", AdministratorConfirmationLive, :edit
      live "/administrators/confirm", AdministratorConfirmationInstructionsLive, :new
    end
  end
end

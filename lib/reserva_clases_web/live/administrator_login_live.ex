defmodule ReservaClasesWeb.AdministratorLoginLive do
  use ReservaClasesWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Inicia sesión de administrador
        <:subtitle>
          Si solo quieres reservar, buscas la
          <.link href={~p"/events"} class="font-semibold text-brand hover:underline">
            Lista de Clases
          </.link>
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="login_form"
        action={~p"/administrators/log_in"}
        phx-update="ignore"
      >
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <.input field={@form[:remember_me]} type="checkbox" label="Mantener la sesión iniciada" />
          <.link href={~p"/administrators/reset_password"} class="text-sm font-semibold">
            Olvidaste tu contraseña?
          </.link>
        </:actions>
        <:actions>
          <.button phx-disable-with="Signing in..." class="w-full">
            Sign in <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "administrator")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end

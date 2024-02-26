defmodule ReservaClasesWeb.ReservationLive.FormComponent do
  use ReservaClasesWeb, :live_component

  alias ReservaClases.Classes

  @turnstile Application.compile_env(:phoenix_turnstile, :adapter, Turnstile)

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Necesitamos estos datos para hacer la reserva.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="reservation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:full_name]} type="text" label="Nombre completo" />
        <.input field={@form[:email]} type="email" label="Email" />
        <.input field={@form[:is_member]} type="checkbox" label="Soy socio/a DAV" />
        <%= if @action == :new_reservation do %>
          <Turnstile.widget theme="light" />
        <% end %>
        <:actions>
          <.button phx-disable-with="Guardando...">Hacer reserva</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{reservation: reservation} = assigns, socket) do
    changeset = Classes.change_reservation(reservation)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :event_id, socket.assigns["event_id"])}
  end

  @impl true
  def handle_event("validate", %{"reservation" => reservation_params}, socket) do
    changeset =
      socket.assigns.reservation
      |> Classes.change_reservation(reservation_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", params = %{"reservation" => _reservation_params}, socket) do
    save_reservation(socket, socket.assigns.action, params)
  end

  defp save_reservation(socket, :edit, %{"reservation" => reservation_params}) do
    case Classes.update_reservation(socket.assigns.reservation, reservation_params) do
      {:ok, reservation} ->
        notify_parent({:saved, reservation})

        {:noreply,
         socket
         |> put_flash(:info, "Reserva modificada")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_reservation(socket, :new_reservation, params = %{"reservation" => reservation_params}) do
    case @turnstile.verify(params) do
      {:ok, _} ->
        save_new_reservation(socket, reservation_params)
      {:error, _} ->
        {:noreply, socket
          |> put_flash(:error, "Error verificando que no eres un robot")
          |> @turnstile.refresh()}
    end
  end

  defp save_new_reservation(socket, reservation_params) do
    case Classes.create_reservation(reservation_params, socket.assigns.event_id) do
      {:ok, reservation} ->
        notify_parent({:saved, reservation})

        {:noreply,
         socket
         |> put_flash(:info, "Reserva creada")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}

      {:error, msg} when is_binary(msg) ->
        {:noreply, socket |> put_flash(:error, msg) |> push_patch(to: socket.assigns.patch)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

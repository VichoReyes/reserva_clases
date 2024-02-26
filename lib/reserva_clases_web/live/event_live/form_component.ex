defmodule ReservaClasesWeb.EventLive.FormComponent do
  use ReservaClasesWeb, :live_component

  alias ReservaClases.Classes

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="event-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Nombre" />
        <.input field={@form[:starts_at]} type="datetime-local" label="Fecha" />
        <.input field={@form[:description]} type="text" label="Descripción" />
        <div>
          <.input field={@form[:total_vacancies]} type="number" label="Cupos totales" />
          <p class="flex gap-1 text-sm leading-6 text-zinc-600">
            <.icon name="hero-question-mark-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
            En caso de que el instructor gestione sus reservas, poner cero.
          </p>
        </div>
        <.input disabled={@action != :new} field={@form[:repeat_weekly]} type="checkbox" label="Se repite semanalmente" />
        <:actions>
          <.button phx-disable-with="Guardando...">Guardar</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{event: event} = assigns, socket) do
    changeset = Classes.change_event(event)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"event" => event_params}, socket) do
    changeset =
      socket.assigns.event
      |> Classes.change_event(event_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"event" => event_params}, socket) do
    save_event(socket, socket.assigns.action, event_params)
  end

  defp save_event(socket, :edit, event_params) do
    case Classes.update_event(socket.assigns.event, event_params) do
      {:ok, event} ->
        notify_parent({:saved, event})

        {:noreply,
         socket
         |> put_flash(:info, "Clase modificada")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_event(socket, :new, event_params) do
    case Classes.create_event(event_params) do
      {:ok, event} ->
        notify_parent({:saved, event})

        {:noreply,
         socket
         |> put_flash(:info, "Clase creada")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

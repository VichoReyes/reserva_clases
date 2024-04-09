defmodule ReservaClasesWeb.EventLive.Show do
  use ReservaClasesWeb, :live_view

  alias ReservaClases.Classes
  import ReservaClases.Calendar

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    event = Classes.get_event!(id, [:reservations])
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action, event))
     |> assign(:event, event)
     |> assign(:event_accepts_reservations, Classes.event_accepts_reservations(event))
     |> assign(:reservation, %Classes.Reservation{event_id: event.id})}
  end

  alias ReservaClases.Classes.Event

  defp page_title(:show, %Event{title: title}), do: "#{title}"
  defp page_title(:edit, %Event{title: title}), do: "Editando #{title}"
  defp page_title(:new_reservation, %Event{title: title}), do: "Nueva reserva en #{title}"

  @impl true
  def handle_event("delete_reservation", %{"id" => id}, socket) do
    if !socket.assigns.current_administrator do
      raise "Unauthorized"
    end
    reservation = Classes.get_reservation!(id)
    event_id = reservation.event_id
    {:ok, _} = Classes.delete_reservation(reservation)
    updated_event = Classes.get_event!(event_id, [:reservations])

    {:noreply, assign(socket, :event, updated_event)}
  end
end

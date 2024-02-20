defmodule ReservaClasesWeb.EventLive.Show do
  use ReservaClasesWeb, :live_view

  alias ReservaClases.Classes

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
     |> assign(:remaining_vacancies, event.total_vacancies - length(event.reservations))
     |> assign(:reservation, %Classes.Reservation{event_id: event.id})}
  end

  defp strftime(time, format) do
    month_names = {"Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"}
    day_of_week_names = {"Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"}
    Calendar.strftime(
      time,
      format,
      month_names: &elem(month_names, &1 - 1),
      day_of_week_names: &elem(day_of_week_names, &1 - 1))
  end

  alias ReservaClases.Classes.Event

  defp page_title(:show, %Event{title: title}), do: "#{title}"
  defp page_title(:edit, %Event{title: title}), do: "Editando #{title}"
  defp page_title(:new_reservation, %Event{title: title}), do: "Nueva reserva en #{title}"
end

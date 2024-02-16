defmodule ReservaClasesWeb.EventLive.Index do
  use ReservaClasesWeb, :live_view

  alias ReservaClases.Classes
  alias ReservaClases.Classes.Event

  @impl true
  def mount(_params, _session, socket) do
    days_of_week = %{
      1 => "Lunes",
      2 => "Martes",
      3 => "Miércoles",
      4 => "Jueves",
      5 => "Viernes",
      6 => "Sábado",
      7 => "Domingo"
    }

    {:ok,
     socket
     |> assign(:days_of_week, days_of_week)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket |> apply_action(socket.assigns.live_action, params) |> put_week_events(params)}
  end

  defp put_week_events(socket, params) do
    week_offset = Map.get(params, "week", "0")
    week_offset = String.to_integer(week_offset)

    socket
    |> assign(:events, Classes.list_events(week_offset))
    |> assign(:week_offset, week_offset)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    event = Classes.get_event!(id)

    socket
    |> assign(:page_title, "Editar #{event.title}")
    |> assign(:event, event)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Nuevo evento")
    |> assign(:event, %Event{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Todos los eventos")
    |> assign(:event, nil)
  end

  @impl true
  def handle_info({ReservaClasesWeb.EventLive.FormComponent, {:saved, _event}}, socket) do
    {:noreply, assign(socket, :events, Classes.list_events())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    event = Classes.get_event!(id)
    {:ok, _} = Classes.delete_event(event)

    {:noreply, assign(socket, :events, Classes.list_events())}
  end
end

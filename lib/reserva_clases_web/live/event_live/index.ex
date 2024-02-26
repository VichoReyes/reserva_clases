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

  defp apply_action(socket, :delete_repeat, %{"id" => id}) do
    event = Classes.get_event!(id)

    socket
    |> assign(:page_title, "Eliminar #{event.title}?")
    |> assign(:event, event)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Nueva clase")
    |> assign(:event, %Event{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Lista de clases")
    |> assign(:event, nil)
  end

  @impl true
  def handle_info({ReservaClasesWeb.EventLive.FormComponent, {:saved, _event}}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id} = details, socket) do
    if !socket.assigns.current_administrator do
      raise "Unauthorized"
    end

    event = Classes.get_event!(id)
    {:ok, _} = case details do
      %{"keep_repetitions" => true} ->
        Classes.delete_event(event, :keep_repetitions)
      %{"keep_repetitions" => false} ->
        Classes.delete_event(event, :delete_repetitions)
      %{} ->
        Classes.delete_event(event)
    end

    # sería tanto más simple reutilizar put_week_events
    # pero no sé de dónde sacar los params.
    new_events =
      socket.assigns.events
      |> Enum.map(fn {day, daylist} ->
        {day, Enum.reject(daylist, fn e -> e.id == event.id end)}
      end)
      |> Enum.reject(fn {_, daylist} -> Enum.empty?(daylist) end)

    {:noreply, assign(socket, :events, new_events)}
  end
end

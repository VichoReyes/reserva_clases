defmodule ReservaClasesWeb.EventLive.Index do
  use ReservaClasesWeb, :live_view

  alias ReservaClases.Classes
  alias ReservaClases.Classes.Event

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :events, Classes.list_events())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
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
  def handle_info({ReservaClasesWeb.EventLive.FormComponent, {:saved, event}}, socket) do
    {:noreply, stream_insert(socket, :events, event)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    event = Classes.get_event!(id)
    {:ok, _} = Classes.delete_event(event)

    {:noreply, stream_delete(socket, :events, event)}
  end
end

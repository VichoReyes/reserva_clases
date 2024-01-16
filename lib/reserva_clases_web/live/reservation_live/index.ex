defmodule ReservaClasesWeb.ReservationLive.Index do
  use ReservaClasesWeb, :live_view

  alias ReservaClases.Classes

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :reservations, Classes.list_reservations())}
  end

  @impl true
  @spec handle_params(any(), any(), %{
          :assigns => atom() | %{:live_action => :edit | :index, optional(any()) => any()},
          optional(any()) => any()
        }) :: {:noreply, map()}
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Reservation")
    |> assign(:reservation, Classes.get_reservation!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Reservations")
    |> assign(:reservation, nil)
  end

  @impl true
  def handle_info({ReservaClasesWeb.ReservationLive.FormComponent, {:saved, reservation}}, socket) do
    {:noreply, stream_insert(socket, :reservations, reservation)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    reservation = Classes.get_reservation!(id)
    {:ok, _} = Classes.delete_reservation(reservation)

    {:noreply, stream_delete(socket, :reservations, reservation)}
  end
end

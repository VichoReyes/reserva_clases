defmodule ReservaClases.Repo.Migrations.DropReservationUniqueEmail do
  use Ecto.Migration

  def change do
    drop unique_index(:reservations, [:email, :event_id])
  end
end

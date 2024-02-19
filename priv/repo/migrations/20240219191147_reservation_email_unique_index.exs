defmodule ReservaClases.Repo.Migrations.ReservationEmailUniqueIndex do
  use Ecto.Migration

  def change do
    create unique_index(:reservations, [:email, :event_id])
  end
end

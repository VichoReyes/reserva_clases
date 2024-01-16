defmodule ReservaClases.Repo.Migrations.CreateReservations do
  use Ecto.Migration

  def change do
    create table(:reservations) do
      add :full_name, :string
      add :email, :string
      add :is_member, :boolean, default: false, null: false
      add :event_id, references(:events, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:reservations, [:event_id])
  end
end

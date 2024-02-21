defmodule ReservaClases.Repo.Migrations.AddEventRepeating do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :repeat_weekly, :boolean, default: false
      add :is_repeat_of, references(:events, on_delete: :nothing)
    end
  end
end

defmodule ReservaClases.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :title, :string
      add :starts_at, :naive_datetime
      add :description, :string
      add :total_vacancies, :integer

      timestamps()
    end
  end
end

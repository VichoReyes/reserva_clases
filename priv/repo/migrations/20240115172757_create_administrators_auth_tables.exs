defmodule ReservaClases.Repo.Migrations.CreateAdministratorsAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:administrators) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:administrators, [:email])

    create table(:administrators_tokens) do
      add :administrator_id, references(:administrators, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:administrators_tokens, [:administrator_id])
    create unique_index(:administrators_tokens, [:context, :token])
  end
end

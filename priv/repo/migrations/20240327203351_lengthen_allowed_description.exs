defmodule ReservaClases.Repo.Migrations.LengthenAllowedDescription do
  use Ecto.Migration

  def change do
    alter table(:events) do
      modify :description, :text
    end
  end
end

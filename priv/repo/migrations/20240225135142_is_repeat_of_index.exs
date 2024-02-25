defmodule ReservaClases.Repo.Migrations.IsRepeatOfIndex do
  use Ecto.Migration

  def change do
    create index(:events, [:is_repeat_of])
  end
end

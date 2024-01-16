defmodule ReservaClases.Classes.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :description, :string
    field :title, :string
    field :starts_at, :naive_datetime
    field :total_vacancies, :integer
    has_many :reservations, ReservaClases.Classes.Reservation

    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:title, :starts_at, :description, :total_vacancies])
    |> validate_required([:title, :starts_at, :total_vacancies])
  end
end

defmodule ReservaClases.Classes.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :description, :string
    field :title, :string
    field :starts_at, :naive_datetime
    field :total_vacancies, :integer
    field :repeat_weekly, :boolean, default: false
    field :is_repeat_of, :id, default: nil
    has_many :reservations, ReservaClases.Classes.Reservation

    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:title, :starts_at, :description, :total_vacancies, :repeat_weekly, :is_repeat_of])
    |> validate_required([:title, :starts_at, :total_vacancies])
  end
end

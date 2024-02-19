defmodule ReservaClases.Classes.Reservation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "reservations" do
    field :is_member, :boolean, default: false
    field :full_name, :string
    field :email, :string
    belongs_to :event, ReservaClases.Classes.Event

    timestamps()
  end

  @doc false
  def changeset(reservation, attrs) do
    reservation
    |> cast(attrs, [:full_name, :email, :is_member])
    |> validate_required([:full_name, :email, :is_member])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unique_constraint(:email, message: "Ya tienes una reserva para esta clase", name: :reservations_email_event_id_index)
  end
end

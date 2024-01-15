defmodule ReservaClases.Repo do
  use Ecto.Repo,
    otp_app: :reserva_clases,
    adapter: Ecto.Adapters.Postgres
end

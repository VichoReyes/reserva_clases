import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :reserva_clases, ReservaClases.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "reserva_clases_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :reserva_clases, ReservaClasesWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "5yJTaLOE3kFSCUgmw6hzYdah59ZqlJncXOeeHUGUJ+ws15AWGikQV7E0oziS3HQT",
  server: false

# In test we don't send emails.
config :reserva_clases, ReservaClases.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

config :phoenix_turnstile, adapter: TurnstileMock

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :turn_junebug_expressway, TurnJunebugExpresswayWeb.Endpoint,
  http: [port: 4001],
  server: false

config :turn_junebug_expressway,
  turn_client: TurnJunebugExpressway.Backends.ClientMock

# Print only warnings and errors during test
config :logger, level: :warn

config :tesla, adapter: Tesla.Mock

# Configure your database
config :turn_junebug_expressway, TurnJunebugExpressway.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "turn_junebug_expressway_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :turn_junebug_expressway, :rabbitmq,
  exchange_name: "test_exchange",
  messages_queue: "test_messages_queue",
  urn: "amqp://guest:guest@localhost:5672/%2f"

config :turn_junebug_expressway, :turn,
  url: System.get_env("TURN_URL", "https://testapp.turn.io/api/whatsapp/channel-id")

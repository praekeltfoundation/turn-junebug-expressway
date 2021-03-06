use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :turn_junebug_expressway, TurnJunebugExpresswayWeb.Endpoint,
  http: [port: 4001],
  server: false

config :turn_junebug_expressway,
  turn_client: TurnJunebugExpressway.Backends.ClientMock,
  rapidpro_client: TurnJunebugExpressway.Backends.ClientMock

# Print only warnings and errors during test
config :logger, level: :warn

config :tesla, adapter: Tesla.Mock

config :turn_junebug_expressway, :rabbitmq,
  exchange_name: "test_exchange",
  messages_queue: "test_messages_queue",
  username: System.get_env("AMQP_USER", "guest"),
  password: System.get_env("AMQP_PASSWORD", "guest"),
  host: System.get_env("AMQP_HOST", "localhost"),
  port: String.to_integer(System.get_env("AMQP_PORT", "5672")),
  vhost: System.get_env("AMQP_VHOST", "/"),
  management_interface: "http://rabbitmq-test:15672"

# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :turn_junebug_expressway, TurnJunebugExpresswayWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "AAo1lJXpZ8mHIIlvwbvmUrcS0vxTmioPPgOsfHCIjawp5jwlesHxp/XI9B33pp5Z",
  render_errors: [view: TurnJunebugExpresswayWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: TurnJunebugExpressway.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :turn_junebug_expressway, :turn,
  base_url: System.get_env("TURN_BASE_URL", "https://testapp.turn.io"),
  event_path: System.get_env("TURN_EVENT_PATH", "api/whatsapp/channel-id"),
  inbound_path: System.get_env("TURN_INBOUND_PATH", "v1/events"),
  token: System.get_env("TURN_TOKEN", "replaceme"),
  hmac_secret: System.get_env("TURN_HMAC_SECRET", "REPLACE_ME")

config :turn_junebug_expressway, :rabbitmq,
  exchange_name: "vumi",
  messages_queue: System.get_env("MESSAGES_QUEUE", "dummy_messages_queue"),
  username: System.get_env("AMQP_USER", "guest"),
  password: System.get_env("AMQP_PASSWORD", "guest"),
  host: System.get_env("AMQP_HOST", "localhost"),
  port: String.to_integer(System.get_env("AMQP_PORT", "5672")),
  vhost: System.get_env("AMQP_VHOST", "/")

config :turn_junebug_expressway, :junebug,
  from_addr: System.get_env("JUNEBUG_FROM_ADDR", "+2712345"),
  transport_type: System.get_env("JUNEBUG_TRANSPORT_TYPE", "telnet")

config :turn_junebug_expressway,
  message_engine: TurnJunebugExpressway.MessageEngine

config :turn_junebug_expressway, :rapidpro,
  channel_url: System.get_env("RAPIDPRO_CHANNEL_URL", "https://test-rp.com/c/wa/channel-id/receive")

config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  environment_name: Mix.env(),
  included_environments: [:prod]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

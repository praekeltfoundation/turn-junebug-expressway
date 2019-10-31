# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :turn_junebug_expressway,
  ecto_repos: [TurnJunebugExpressway.Repo]

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

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

config :phoenix, :json_library, Jason

config :turn_junebug_expressway, :turn,
  hmac_secret: System.get_env("TURN_HMAC_SECRET") || "REPLACE_ME"

config :turn_junebug_expressway, :junebug,
  from_addr: System.get_env("JUNEBUG_FROM_ADDR") || "+2712345",
  transport_type: System.get_env("JUNEBUG_TRANSPORT_TYPE") || "telnet"

config :turn_junebug_expressway,
  message_engine: TurnJunebugExpressway.MessageEngine

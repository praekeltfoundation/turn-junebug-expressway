# Turn Junebug Expressway
A turn fallback channel specifically for Junebug.

To run the tests locally:

  * Install dependencies with `mix deps.get`
  * Run `docker-compose -f docker-compose-dev.yml up` to start required services.
  * Run tests with `mix test`

## Environment Variables

#### Turn
* `TURN_BASE_URL` - Base URL for Turn
* `TURN_EVENT_PATH` - Path to send events to turn
* `TURN_INBOUND_PATH` - Path to send inbounds to turn, defaults to `v1/events`
* `TURN_TOKEN` - Token to authenticate Turn requests
* `TURN_HMAC_SECRET` - HMAC secret to verify incoming requests from Turn

#### Rapidpro
* `RAPIDPRO_CHANNEL_URL` - Rapidpro channel URL to send inbounds/events to

#### Junebug
* `MESSAGES_QUEUE` - AMQP queue where junebug is consuming from.
* `JUNEBUG_TRANSPORT_TYPE` - Transport type used in message payload sent to Junebug
* `JUNEBUG_FROM_ADDR` - From address used in message payload sent to Junebug
* `AMQP_HOST` - AMQP host for Junebug
* `AMQP_USER` - AMQP user for Junebug
* `AMQP_PASSWORD` - AMQP password for Junebug
* `AMQP_VHOST` - AMQP vhost for Junebug

#### Other
* `SENTRY_DSN` - The sentry dsn to send exceptions to.
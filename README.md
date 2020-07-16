# Turn Junebug Expressway
*A turn fallback channel specifically for Junebug.*

The expressway app will accept messages from turn on the `/api/v1/send_message` endpoint and forward it to Junebug by placing it on the message queue configured. This needs to be configured on the turn settings page.

Any events received from Junebug on the messages queue will be forwarded to Turn on the event path configured.

Any inbounds received from Junebug on the messages queue will be forwarded to Turn on the inbound path configured and to Rapidpro on the configured channel.

Turn sends a HMAC signature with each request, expressway will use the HMAC secret configured to validate the origin of each request. The HMAC secret can be found in the turn settings.

Related Turn docs: https://whatsapp.praekelt.org/docs/index.html#turn-fallback-channel

#### To run the tests locally:

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
* `QUEUE_CONCURRENCY` - Amount of messages pulled from queue to process concurrently, defaults to 1
* `JUNEBUG_TRANSPORT_TYPE` - Transport type used in message payload sent to Junebug
* `JUNEBUG_FROM_ADDR` - From address used in message payload sent to Junebug
* `AMQP_HOST` - AMQP host for Junebug
* `AMQP_USER` - AMQP user for Junebug
* `AMQP_PASSWORD` - AMQP password for Junebug
* `AMQP_VHOST` - AMQP vhost for Junebug

#### Other
* `SENTRY_DSN` - The sentry dsn to send exceptions to.

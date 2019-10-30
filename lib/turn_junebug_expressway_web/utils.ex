defmodule TurnJunebugExpresswayWeb.Utils do
  def get_env(section, key) do
    Application.get_env(:turn_junebug_expressway, section)[key]
  end

  def validate_hmac_signature(conn) do
    header_hmac =
      conn.req_headers
      |> Enum.into(%{})
      |> Map.get("http_x_engage_hook_signature")

    our_hmac =
      :crypto.hmac(
        :sha256,
        get_env(:turn, :hmac_secret),
        conn.private[:raw_body]
      )
      |> Base.encode64()

    case {header_hmac, our_hmac == header_hmac} do
      {nil, _} -> {:error, "missing hmac signature"}
      {_, false} -> {:error, "invalid hmac signature"}
      {_, true} -> {:ok, "good hmac"}
    end
  end

  def format_message(conn) do
    {:ok, body} = Jason.decode(conn.private[:raw_body])

    {:ok,
     %{
       "content" => get_in(body, ["text", "body"]),
       "message_version" => "1",
       "to_addr" => get_in(body, ["to"]),
       "from_addr" => get_env(:junebug, :from_addr),
       # TODO: randomly generate this:
       "message_id" => "long_random_message_id"
     }}
  end

  def send_message(message) do
    options = [
      host: get_env(:rabbitmq, :host),
      port: get_env(:rabbitmq, :port),
      virtual_host: get_env(:rabbitmq, :vhost),
      username: get_env(:rabbitmq, :user),
      password: get_env(:rabbitmq, :password)
    ]

    {:ok, connection} = AMQP.Connection.open(options, :undefined)
    {:ok, channel} = AMQP.Channel.open(connection)

    queue_name = get_env(:rabbitmq, :messages_queue)

    AMQP.Basic.publish(channel, "vumi", "#{queue_name}.outbound", Jason.encode!(message))
    AMQP.Connection.close(connection)
  end
end

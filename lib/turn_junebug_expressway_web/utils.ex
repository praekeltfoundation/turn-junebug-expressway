defmodule TurnJunebugExpresswayWeb.Utils do
  use Tesla

  @client Application.get_env(:turn_junebug_expressway, :turn_client)

  def get_env(section, key) do
    Application.get_env(:turn_junebug_expressway, section)[key]
  end

  def validate_hmac_signature(conn) do
    header_hmac =
      conn.req_headers
      |> Enum.into(%{})
      |> Map.get("x-turn-hook-signature")

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

    IO.puts(">>> format message")
    # credo:disable-for-next-line
    IO.inspect(body)

    today = DateTime.utc_now()

    {:ok,
     %{
       "content" => get_in(body, ["text", "body"]),
       "message_version" => "20110921",
       "message_type" => "user_message",
       "to_addr" => Map.get(body, "to"),
       "from_addr" => get_env(:junebug, :from_addr),
       "message_id" => Ecto.UUID.generate(),
       "timestamp" => DateTime.to_string(today),
       "in_reply_to" => nil,
       "session_event" => nil,
       "transport_name" => get_env(:rabbitmq, :messages_queue),
       "transport_type" => get_env(:junebug, :transport_type),
       "transport_metadata" => %{}
     }}
  end

  def send_message(message) do
    TurnJunebugExpressway.MessageEngine.publish_message(message)
  end

  def get_event_timestamp(event) do
    event
    |> Map.get("timestamp")
    |> Timex.parse!("%Y-%m-%d %H:%M:%S.%f", :strftime)
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_unix(:millisecond)
    |> to_string()
  end

  def get_event_status(event) do
    status =
      %{
        "ack" => "sent",
        "nack" => "failed",
        "delivery_report" => "delivery_report"
      }
      |> Map.get(Map.get(event, "event_type"))

    case status do
      "delivery_report" ->
        status =
          %{
            "failed" => "failed",
            "delivered" => "delivered"
          }
          |> Map.get(Map.get(event, "delivery_status"))

        case status do
          nil -> {:ignore, status}
          status -> {:ok, status}
        end

      status ->
        {:ok, status}
    end
  end

  def handle_incoming_event(payload) do
    data = Jason.decode!(payload)

    case Map.get(data, "message_type") do
      "event" -> forward_event(data)
      "user_message" -> forward_inbound(data)
      nil -> :ok
    end
  end

  def forward_event(event) do
    case event |> get_event_status do
      {:ignore, _} ->
        :ok

      {:ok, status} ->
        @client.client()
        |> @client.post_event(%{
          "statuses" => [
            %{
              "id" => Map.get(event, "user_message_id"),
              "recipient_id" => nil,
              "status" => status,
              "timestamp" => get_event_timestamp(event)
            }
          ]
        })
    end
  end

  def format_urn(urn) do
    case urn do
      "+" <> urn -> "+" <> urn
      urn -> "+" <> urn
    end
  end

  def forward_inbound(inbound) do
    urn = format_urn(Map.get(inbound, "from_addr"))

    message = %{
      "event_type" => "external_message",
      "urn" => urn,
      "timestamp" => get_event_timestamp(inbound),
      "event_id" => Map.get(inbound, "message_id"),
      "details" => %{
        "content" => Map.get(inbound, "content"),
        "direction" => "inbound",
        "from_addr" => urn
      }
    }

    IO.puts(">>> forward_inbound")
    # credo:disable-for-next-line
    IO.inspect(message)

    @client.client()
    |> @client.post_inbound(message)
  end
end

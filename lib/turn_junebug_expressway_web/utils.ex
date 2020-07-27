defmodule TurnJunebugExpresswayWeb.Utils do
  use Tesla

  @turn_client Application.get_env(:turn_junebug_expressway, :turn_client)
  @rapidpro_client Application.get_env(:turn_junebug_expressway, :rapidpro_client)

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

    # IO.puts(">>> format message")
    # # credo:disable-for-next-line
    # IO.inspect(body)

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

  def send_message(%{"content" => content} = _message) when content == nil do
    # Do nothing
    :ok
  end

  def send_message(message) do
    TurnJunebugExpressway.MessageEngine.publish_message(message)
  end

  def get_event_timestamp(event, level \\ :millisecond) do
    event
    |> Map.get("timestamp")
    |> Timex.parse!("%Y-%m-%d %H:%M:%S.%f", :strftime)
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_unix(level)
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
        @turn_client.client()
        |> @turn_client.post_event(%{
          "statuses" => [
            %{
              "id" => Map.get(event, "user_message_id"),
              "recipient_id" => nil,
              "status" => status,
              "timestamp" => get_event_timestamp(event, :second)
            }
          ]
        })
    end
  end

  def format_urn(urn, :turn) do
    case urn do
      "+" <> urn -> "+" <> urn
      urn -> "+" <> urn
    end
  end

  def format_urn(urn, :rapidpro) do
    String.replace_prefix(urn, "+", "")
  end

  def forward_inbound(inbound) do
    turn_urn = format_urn(Map.get(inbound, "from_addr"), :turn)
    rapidpro_urn = format_urn(Map.get(inbound, "from_addr"), :rapidpro)
    timestamp = get_event_timestamp(inbound)

    message = %{
      "event_type" => "external_message",
      "urn" => turn_urn,
      "timestamp" => timestamp,
      "event_id" => Map.get(inbound, "message_id"),
      "details" => %{
        "content" => Map.get(inbound, "content"),
        "direction" => "inbound",
        "from_addr" => turn_urn
      }
    }

    # IO.puts(">>> forward_inbound turn")
    # # credo:disable-for-next-line
    # IO.inspect(message)

    case @turn_client.client()
         |> @turn_client.post_inbound(message) do
      :ok ->
        timestamp = get_event_timestamp(inbound, :second)

        rp_message = %{
          "messages" => [
            %{
              "id" => Map.get(inbound, "message_id"),
              "from" => rapidpro_urn,
              "text" => %{"body" => Map.get(inbound, "content")},
              "timestamp" => timestamp,
              "to" => rapidpro_urn,
              "type" => "text"
            }
          ]
        }

        # IO.puts(">>> forward_inbound rapidpro")
        # # credo:disable-for-next-line
        # IO.inspect(rp_message)

        @rapidpro_client.client()
        |> @rapidpro_client.post_inbound(rp_message)

      error ->
        error
    end
  end

  def get_queue_info(client, vhost, queue_name) do
    {:ok, %Tesla.Env{body: body}} = client |> get("/api/queues/#{vhost}/#{queue_name}")

    messages = body |> Map.get("messages")
    rate = get_in(body, ["message_stats", "ack_details", "rate"])

    stuck =
      case {rate, messages} do
        {nil, _} -> false
        {rate, messages} when rate == 0 and messages == 0 -> false
        {rate, messages} when rate > 0 and messages > 0 -> false
        {rate, messages} when rate <= 0 and messages > 0 -> true
      end

    %{"name" => "#{queue_name}", "stuck" => stuck, "messages" => messages}
  end

  def get_all_queue_details(management_interface) do
    queue_name = get_env(:rabbitmq, :messages_queue)
    username = get_env(:rabbitmq, :username)
    password = get_env(:rabbitmq, :password)
    vhost = String.replace(get_env(:rabbitmq, :vhost), "/", "%2f")

    middleware = [
      {Tesla.Middleware.BaseUrl, management_interface},
      {Tesla.Middleware.BasicAuth, %{username: username, password: password}},
      Tesla.Middleware.JSON
    ]

    client = Tesla.client(middleware)

    results =
      ["event", "inbound"]
      |> Enum.map(fn queue ->
        client
        |> get_queue_info(vhost, "#{queue_name}.#{queue}")
      end)

    stuck_queues =
      results
      |> Enum.filter(fn
        %{"stuck" => true} -> true
        %{"stuck" => false} -> false
      end)

    {Enum.count(stuck_queues) > 0, results}
  end
end

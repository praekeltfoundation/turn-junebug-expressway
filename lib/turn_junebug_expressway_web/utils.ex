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

  def format_to_addr(to) do
    case String.starts_with?(to, "+") do
      true -> to
      false -> "+" <> to
    end
  end

  def format_message(conn) do
    {:ok, body} = Jason.decode(conn.private[:raw_body])

    IO.puts(">>> format message")
    # credo:disable-for-next-line
    IO.inspect(body)

    to =
      body
      |> Map.get("to")

    # |> format_to_addr

    today = DateTime.utc_now()

    {:ok,
     %{
       "content" => get_in(body, ["text", "body"]),
       "message_version" => "20110921",
       "message_type" => "user_message",
       "to_addr" => to,
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
    |> DateTime.to_unix()
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

  def forward_event(payload) do
    {:ok, event} = Jason.decode(payload)

    case event |> get_event_status do
      {:ignore, _} ->
        :ok

      {:ok, status} ->
        case @client.client()
             |> @client.post("", %{
               "statuses" => [
                 %{
                   "id" => Map.get(event, "user_message_id"),
                   "recipient_id" => nil,
                   "status" => status,
                   "timestamp" => get_event_timestamp(event)
                 }
               ]
             }) do
          {:ok, %Tesla.Env{status: status}}
          when status in 200..299 ->
            :ok

          {:ok, %Tesla.Env{status: status} = reason} ->
            {:error, status, reason}

          {:error, %Tesla.Env{status: status} = reason} ->
            {:error, status, reason}
        end
    end
  end
end

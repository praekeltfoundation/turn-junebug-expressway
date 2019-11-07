defmodule TurnJunebugExpresswayWeb.MessageControllerTest do
  use TurnJunebugExpresswayWeb.ConnCase

  alias TurnJunebugExpresswayWeb.Utils

  setup %{conn: conn} do
    exchange_name = Utils.get_env(:rabbitmq, :exchange_name)
    queue_name = Utils.get_env(:rabbitmq, :messages_queue)

    channel = TurnJunebugExpressway.MessageEngine.get_channel()

    AMQP.Queue.declare(channel, "#{queue_name}.outbound")
    AMQP.Queue.bind(channel, "#{queue_name}.outbound", exchange_name)

    {:ok, conn: conn, channel: channel}
  end

  describe "validate hmac signature in header" do
    test "error when hmac header is invalid", %{} do
      conn =
        build_conn()
        |> put_req_header("x-turn-hook-signature", "bla bla bla")
        |> post("/api/v1/send_message", test: "test")

      assert conn.status == 403
      assert conn.resp_body =~ "invalid hmac signature"
    end

    test "missing?", %{} do
      conn =
        build_conn()
        |> post("/api/v1/send_message", test: "test")

      assert conn.status == 403
      assert conn.resp_body =~ "missing hmac signature"
    end

    test "success when hmac header is valid",
         %{
           # channel: channel
         } do
      {:ok, data} =
        Jason.encode(%{
          "preview_url" => false,
          "recipient_type" => "individual",
          "text" => %{"body" => "text message content"},
          "to" => "whatsapp_id",
          "type" => "text"
        })

      # queue_name = Utils.get_env(:rabbitmq, :messages_queue)

      # TODO: fix this test, this never gets executed.
      # it does work when running locally
      # AMQP.Queue.subscribe(channel, "#{queue_name}.outbound", fn payload, _meta ->
      #   {:ok,
      #    %{
      #      "content" => content,
      #      "from_addr" => from_addr,
      #      "in_reply_to" => in_reply_to,
      #      "message_id" => message_id,
      #      "message_type" => message_type,
      #      "message_version" => message_version,
      #      "session_event" => session_event,
      #      "timestamp" => timestamp,
      #      "to_addr" => to_addr,
      #      "transport_metadata" => transport_metadata,
      #      "transport_name" => transport_name,
      #      "transport_type" => transport_type
      #    }} = Jason.decode(payload)

      #   assert content == "text message content"
      #   assert from_addr == "+2712345"
      #   assert in_reply_to == nil
      #   assert message_id != nil
      #   assert message_type == "user_message"
      #   assert message_version == "20110921"
      #   assert session_event == nil
      #   assert timestamp != nil
      #   assert to_addr == "whatsapp_id"
      #   assert transport_metadata == %{}
      #   assert transport_name == "dummy_messages_queue"
      #   assert transport_type == "telnet"
      # end)

      conn =
        build_conn()
        |> put_req_header(
          "x-turn-hook-signature",
          "jW/nhuaGDB2IMv2nBlzEngmBGiHX4cZeTsSHuiESTmc="
        )
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/send_message", data)

      assert conn.status == 202
      {:ok, %{"messages" => [%{"id" => message_id}]}} = Jason.decode(conn.resp_body)

      assert message_id != nil
    end
  end
end

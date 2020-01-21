defmodule TurnJunebugExpresswayWeb.UtilsTest do
  use(ExUnit.Case)

  import Mox

  alias TurnJunebugExpresswayWeb.Utils

  describe "format_urn" do
    test "format_urn/1 with +" do
      assert Utils.format_urn("+123") == "+123"
    end

    test "format_urn/1 without +" do
      assert Utils.format_urn("123") == "+123"
    end
  end

  describe "handle_incoming_event" do
    test "sends event back to turn", %{} do
      body = %{
        "statuses" => [
          %{
            "id" => "f74c4e6108d8418ab53dbcfd628242f3",
            "recipient_id" => nil,
            "status" => "sent",
            "timestamp" => "1572525144930"
          }
        ]
      }

      TurnJunebugExpressway.Backends.ClientMock
      |> expect(:client, fn -> :client end)
      |> expect(:post_event, fn :client, ^body -> :ok end)

      event = %{
        "transport_name" => "d49d3569-47d5-47a0-8074-5a7ffa684832",
        "event_type" => "ack",
        "event_id" => "b3db4f670d4c4e2297c58a6dc5b72980",
        "sent_message_id" => "f74c4e6108d8418ab53dbcfd628242f3",
        "helper_metadata" => %{},
        "routing_metadata" => %{},
        "message_version" => "20110921",
        "timestamp" => "2019-10-31 12:32:24.930687",
        "transport_metadata" => %{},
        "user_message_id" => "f74c4e6108d8418ab53dbcfd628242f3",
        "message_type" => "event"
      }

      :ok = Utils.handle_incoming_event(Jason.encode!(event))
    end

    test "ignore pending delivery_report", %{} do
      event = %{
        "transport_name" => "d49d3569-47d5-47a0-8074-5a7ffa684832",
        "event_type" => "delivery_report",
        "event_id" => "b3db4f670d4c4e2297c58a6dc5b72980",
        "delivery_status" => "pending",
        "helper_metadata" => %{},
        "routing_metadata" => %{},
        "message_version" => "20110921",
        "timestamp" => "2019-10-31 12:32:24.930687",
        "transport_metadata" => %{},
        "user_message_id" => "f74c4e6108d8418ab53dbcfd628242f3",
        "message_type" => "event"
      }

      :ok = Utils.handle_incoming_event(Jason.encode!(event))
    end

    test "send incoming message to turn", %{} do
      turn_body = %{
        "details" => %{
          "content" => "Hello my name is ...",
          "direction" => "inbound",
          "from_addr" => "+271234"
        },
        "event_id" => "f74c4e6108d8418ab53dbcfd628242f3",
        "event_type" => "external_message",
        "timestamp" => "1572525144930",
        "urn" => "+271234"
      }

      rp_body = %{
        "messages" => [
          %{
            "id" => "f74c4e6108d8418ab53dbcfd628242f3",
            "from" => "+271234",
            "text" => %{"body" => "Hello my name is ..."},
            "timestamp" => "1572525144930",
            "to" => "+271234",
            "type" => "text"
          }
        ]
      }

      TurnJunebugExpressway.Backends.ClientMock
      |> expect(:client, 2, fn -> :client end)
      |> expect(:post_inbound, fn :client, ^turn_body -> :ok end)
      |> expect(:post_inbound, fn :client, ^rp_body -> :ok end)

      event = %{
        "message_type" => "user_message",
        "from_addr" => "271234",
        "timestamp" => "2019-10-31 12:32:24.930687",
        "message_id" => "f74c4e6108d8418ab53dbcfd628242f3",
        "content" => "Hello my name is ..."
      }

      :ok = Utils.handle_incoming_event(Jason.encode!(event))
    end
  end
end

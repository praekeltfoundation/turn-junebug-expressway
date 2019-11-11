defmodule TurnJunebugExpresswayWeb.UtilsTest do
  use(ExUnit.Case)

  import Mox

  alias TurnJunebugExpresswayWeb.Utils

  describe "forward_event" do
    test "sends event back to turn", %{} do
      body = %{
        "statuses" => [
          %{
            "id" => "f74c4e6108d8418ab53dbcfd628242f3",
            "recipient_id" => nil,
            "status" => "sent",
            "timestamp" => "1572525144"
          }
        ]
      }

      TurnJunebugExpressway.Backends.ClientMock
      |> expect(:client, fn -> :client end)
      |> expect(:post, fn :client, "", ^body ->
        {:ok,
         %Tesla.Env{
           status: 200
         }}
      end)

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

      :ok = Utils.forward_event(Jason.encode!(event))
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

      :ok = Utils.forward_event(Jason.encode!(event))
    end
  end
end

defmodule TurnJunebugExpresswayWeb.DefaultControllerTest do
  use TurnJunebugExpresswayWeb.ConnCase
  import Tesla.Mock

  describe "health endpoint" do
    test "get should return 200", %{} do
      original_config = Application.get_env(:turn_junebug_expressway, :rabbitmq)
      on_exit(fn -> Application.put_env(:turn_junebug_expressway, :rabbitmq, original_config) end)

      Application.put_env(:turn_junebug_expressway, :rabbitmq, management_interface: nil)

      conn =
        build_conn()
        |> get("/health")

      assert conn.status == 200
      assert conn.resp_body =~ "All good"
    end

    test "get should return 200 if all queues are ok", %{} do
      mock(fn
        %{
          method: :get,
          url: "http://rabbitmq-test:15672/api/queues/%2f/test_messages_queue.event",
          headers: [{"authorization", "Basic Z3Vlc3Q6Z3Vlc3Q="}]
        } ->
          json(%{
            "messages" => 100,
            "message_stats" => %{
              "ack_details" => %{
                rate: 1.0
              }
            }
          })

        %{
          method: :get,
          url: "http://rabbitmq-test:15672/api/queues/%2f/test_messages_queue.inbound",
          headers: [{"authorization", "Basic Z3Vlc3Q6Z3Vlc3Q="}]
        } ->
          json(%{
            "messages" => 0
          })
      end)

      conn =
        build_conn()
        |> get("/health")

      assert conn.status == 200

      assert Jason.decode!(conn.resp_body) == %{
               "description" => "queues ok",
               "result" => [
                 %{"messages" => 100, "name" => "test_messages_queue.event", "stuck" => false},
                 %{"messages" => 0, "name" => "test_messages_queue.inbound", "stuck" => false}
               ]
             }
    end

    test "get should return 500 if there is a queue that is stuck", %{} do
      mock(fn
        %{
          method: :get,
          url: "http://rabbitmq-test:15672/api/queues/%2f/test_messages_queue.event",
          headers: [{"authorization", "Basic Z3Vlc3Q6Z3Vlc3Q="}]
        } ->
          json(%{
            "messages" => 100,
            "message_stats" => %{
              "ack_details" => %{
                rate: 0.0
              }
            }
          })

        %{
          method: :get,
          url: "http://rabbitmq-test:15672/api/queues/%2f/test_messages_queue.inbound",
          headers: [{"authorization", "Basic Z3Vlc3Q6Z3Vlc3Q="}]
        } ->
          json(%{
            "messages" => 0
          })
      end)

      conn =
        build_conn()
        |> get("/health")

      assert conn.status == 500

      assert Jason.decode!(conn.resp_body) == %{
               "description" => "queues stuck",
               "result" => [
                 %{"messages" => 100, "name" => "test_messages_queue.event", "stuck" => true},
                 %{"messages" => 0, "name" => "test_messages_queue.inbound", "stuck" => false}
               ]
             }
    end
  end
end

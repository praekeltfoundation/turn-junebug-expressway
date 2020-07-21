defmodule TurnJunebugExpressway.Behaviours.TurnClientBehaviourTest do
  use TurnJunebugExpressway.DataCase

  alias TurnJunebugExpressway.TurnClient
  alias TurnJunebugExpresswayWeb.Utils

  import Tesla.Mock

  describe "client behaviour" do
    test "post_event/2 should post to the fallback channel", %{} do
      mock(fn %{
                method: :post,
                url: "https://testapp.turn.io/api/whatsapp/channel-id",
                body: body,
                headers: headers
              } ->
        assert Jason.decode!(body) == %{"some" => "event"}
        assert headers == [{"x-turn-fallback-channel", "1"}, {"content-type", "application/json"}]
        json(%{})
      end)

      client = TurnClient.client()
      TurnClient.post_event(client, %{"some" => "event"})
    end

    test "post_event/2 should return string error in the correct format", %{} do
      mock(fn %{
                method: :post,
                url: "https://testapp.turn.io/api/whatsapp/channel-id",
                body: _body
              } ->
        %Tesla.Env{
          body: "bad gateway",
          method: :post,
          status: 502
        }
      end)

      client = TurnClient.client()
      {:error, status, reason} = TurnClient.post_event(client, %{"some" => "event"})

      assert status == 502
      assert reason == "bad gateway"
    end

    test "post_event/2 should return map error in the correct format", %{} do
      mock(fn %{
                method: :post,
                url: "https://testapp.turn.io/api/whatsapp/channel-id",
                body: _body
              } ->
        body = %Tesla.Env{
          body: %{"error" => "bad gateway", "test" => %{"nested" => "yes"}},
          method: :post,
          status: 502
        }
      end)

      client = TurnClient.client()
      {:error, status, reason} = TurnClient.post_event(client, %{"some" => "event"})

      assert status == 502
      assert reason == "error: bad gateway, test: nested: yes"
    end

    test "post_inbound/2 should post to the fallback channel", %{} do
      mock(fn %{
                method: :post,
                url: "https://testapp.turn.io/v1/events",
                body: body,
                headers: headers
              } ->
        assert Jason.decode!(body) == %{"some" => "inbound"}

        assert headers == [
                 {"x-turn-fallback-channel", "1"},
                 {"authorization", "Bearer " <> Utils.get_env(:turn, :token)},
                 {"accept", "application/vnd.v1+json"},
                 {"content-type", "application/json"}
               ]

        json(%{})
      end)

      client = TurnClient.client()
      TurnClient.post_inbound(client, %{"some" => "inbound"})
    end
  end
end

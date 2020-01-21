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
        headers == [{"x-turn-fallback-channel", "1"}]
        json(%{})
      end)

      client = TurnClient.client()
      TurnClient.post_event(client, %{"some" => "event"})
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

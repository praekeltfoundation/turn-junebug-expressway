defmodule TurnJunebugExpressway.Behaviours.RapidproClientBehaviourTest do
  use TurnJunebugExpressway.DataCase

  alias TurnJunebugExpressway.RapidproClient

  import Tesla.Mock

  describe "client behaviour" do
    test "post_inbound/2 should post to rapidpro", %{} do
      mock(fn %{
                method: :post,
                url: "https://test-rp.com/c/wa/channel-id/receive",
                body: body,
                headers: headers
              } ->
        assert Jason.decode!(body) == %{"some" => "inbound"}

        assert headers == [{"content-type", "application/json"}]

        json(%{})
      end)

      client = RapidproClient.client()
      RapidproClient.post_inbound(client, %{"some" => "inbound"})
    end
  end
end

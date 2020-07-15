defmodule TurnJunebugExpressway.TurnClient do
  use TurnJunebugExpressway.Behaviours.ClientBehaviour

  alias TurnJunebugExpresswayWeb.Utils

  def client() do
    default_middleware = [
      {Tesla.Middleware.BaseUrl, Utils.get_env(:turn, :base_url)},
      Tesla.Middleware.JSON
    ]

    middleware =
      case Mix.env() do
        :prod ->
          default_middleware
          |> Enum.concat([{Tesla.Middleware.Timeout, [timeout: 2000]}])

        _ ->
          default_middleware
      end

    Tesla.client(middleware)
  end

  def post_event(client, body) do
    client
    |> do_post(Utils.get_env(:turn, :event_path), body, [{"x-turn-fallback-channel", "1"}])
  end

  def post_inbound(client, body) do
    client
    |> do_post(Utils.get_env(:turn, :inbound_path), body, [
      {"x-turn-fallback-channel", "1"},
      {"authorization", "Bearer " <> Utils.get_env(:turn, :token)},
      {"accept", "application/vnd.v1+json"}
    ])
  end
end

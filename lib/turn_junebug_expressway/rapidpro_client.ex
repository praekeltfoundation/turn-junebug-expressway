defmodule TurnJunebugExpressway.RapidproClient do
  use TurnJunebugExpressway.Behaviours.ClientBehaviour

  alias TurnJunebugExpresswayWeb.Utils

  def client() do
    default_middleware = [
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

  def post_event(_client, _body) do
    :ok
  end

  @spec post_inbound(Tesla.Client.t(), any) :: :ok | {:error, any, Tesla.Env.t()}
  def post_inbound(client, body) do
    client
    |> do_post(Utils.get_env(:rapidpro, :channel_url), body)
  end
end

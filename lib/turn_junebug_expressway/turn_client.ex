defmodule TurnJunebugExpressway.TurnClient do
  # use Tesla
  use TurnJunebugExpressway.Behaviours.ClientBehaviour

  alias TurnJunebugExpresswayWeb.Utils

  def client() do
    default_middleware = [
      {Tesla.Middleware.BaseUrl, Utils.get_env(:turn, :url)},
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

  def post(client, path, body) do
    client
    |> post(path, body)
  end
end

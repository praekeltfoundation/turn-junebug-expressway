defmodule TurnJunebugExpressway.TurnClient do
  # use Tesla
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

  def post(client, path, body) do
    case client
         |> post(path, body) do
      {:ok, %Tesla.Env{status: status}}
      when status in 200..299 ->
        :ok

      {:ok, %Tesla.Env{status: status} = reason} ->
        {:error, status, reason}

      {:error, %Tesla.Env{status: status} = reason} ->
        {:error, status, reason}
    end
  end
end

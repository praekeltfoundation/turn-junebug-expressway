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

  def post_event(client, body) do
    client
    |> do_post(Utils.get_env(:turn, :event_path), body)
  end

  def post_inbound(client, body) do
    client
    |> do_post(Utils.get_env(:turn, :inbound_path), body, [
      {"authorization", "Bearer " <> Utils.get_env(:turn, :token)},
      {"accept", "application/vnd.v1+json"}
    ])
  end

  def do_post(client, path, body, headers \\ []) do
    case client
         |> post(path, body,
           headers: [
             {"x-turn-fallback-channel", "1"} | headers
           ]
         ) do
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

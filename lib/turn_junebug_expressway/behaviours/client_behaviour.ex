defmodule TurnJunebugExpressway.Behaviours.ClientBehaviour do
  defstruct []
  @type t :: %__MODULE__{}

  @type body :: map
  @type client :: map
  @type status :: any
  @type reason :: Tesla.Env.t()

  @callback client() :: client
  @callback post_event(client, body) :: :ok | {:error, status, reason}
  @callback post_inbound(client, body) :: :ok | {:error, status, reason}

  defmacro __using__(_opts) do
    quote do
      @behaviour TurnJunebugExpressway.Behaviours.ClientBehaviour
      use Tesla

      def format_error(body) when is_map(body) do
        body
        |> Map.keys()
        |> Enum.map(fn key -> "#{key}: #{format_error(body[key])}" end)
        |> Enum.join(", ")
      end

      def format_error(body) do
        body
      end

      def do_post(client, path, body, headers \\ []) do
        case client
             |> post(path, body, headers: headers) do
          {:ok, %Tesla.Env{status: status}} when status in 200..299 ->
            :ok

          {:ok, %Tesla.Env{status: status, body: body}} ->
            {:error, status, format_error(body)}

          {:error, %Tesla.Env{status: status, body: body}} ->
            {:error, status, format_error(body)}

          {:error, reason} when is_atom(reason) ->
            {:error, 503, reason}
        end
      end
    end
  end
end

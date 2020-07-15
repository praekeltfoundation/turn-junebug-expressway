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

      def do_post(client, path, body, headers \\ []) do
        case client
             |> post(path, body, headers: headers) do
          {:ok, %Tesla.Env{status: status}} when status in 200..299 ->
            :ok

          {:ok, %Tesla.Env{status: status} = reason} ->
            {:error, status, reason}

          {:error, %Tesla.Env{status: status} = reason} ->
            {:error, status, reason}

          {:error, reason} when is_atom(reason) ->
            {:error, 503, reason}
        end
      end
    end
  end
end

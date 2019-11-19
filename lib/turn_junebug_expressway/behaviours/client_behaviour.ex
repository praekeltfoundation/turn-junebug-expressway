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
    end
  end
end

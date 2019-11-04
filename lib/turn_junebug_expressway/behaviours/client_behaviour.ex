defmodule TurnJunebugExpressway.Behaviours.ClientBehaviour do
  defstruct []
  @type t :: %__MODULE__{}

  @type body :: map
  @type client :: map
  @type path :: String.t()

  @callback client() :: client
  @callback post(client, path, body) :: Tesla.Env.result()

  defmacro __using__(_opts) do
    quote do
      @behaviour TurnJunebugExpressway.Behaviours.ClientBehaviour
      use Tesla
    end
  end
end

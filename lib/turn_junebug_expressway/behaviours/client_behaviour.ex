defmodule TurnJunebugExpressway.Behaviours.ClientBehaviour do
  defstruct []
  @type t :: %__MODULE__{}

  @type body :: map
  @type client :: map

  @callback client() :: client
  @callback post_event(client, body) :: Tesla.Env.result()
  @callback post_inbound(client, body) :: Tesla.Env.result()

  defmacro __using__(_opts) do
    quote do
      @behaviour TurnJunebugExpressway.Behaviours.ClientBehaviour
      use Tesla
    end
  end
end

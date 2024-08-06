defmodule TurnJunebugExpressway.MessageRecipientIdCache do
  use GenServer

  def start_link(options \\ []) do
    {name, options} = Keyword.pop(options, :name, __MODULE__)
    GenServer.start_link(__MODULE__, options, name: name)
  end

  def put(
        pid,
        key,
        value,
        ttl \\ Application.get_env(:turn_junebug_expressway, :cache_ttl, 10_000)
      ) do
    GenServer.call(pid, {:put, key, value, ttl})
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  # GenServer callbacks

  def init(_) do
    state = %{}
    {:ok, state}
  end

  def handle_call({:put, key, value, ttl}, _from, state) do
    Process.send_after(self(), {:expire, key}, ttl)
    {:reply, :ok, Map.put(state, key, value)}
  end

  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state, key), state}
  end

  def handle_info({:expire, key}, state) do
    {:noreply, Map.delete(state, key)}
  end
end

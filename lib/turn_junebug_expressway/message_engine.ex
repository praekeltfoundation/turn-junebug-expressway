defmodule TurnJunebugExpressway.MessageEngine do
  use GenServer
  use AMQP

  require Logger
  alias AMQP.Connection

  alias TurnJunebugExpresswayWeb.Utils

  @host Utils.get_env(:rabbitmq, :urn)
  @exchange_name Utils.get_env(:rabbitmq, :exchange_name)
  @queue_name Utils.get_env(:rabbitmq, :messages_queue)
  @reconnect_interval 10_000

  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  def init(_) do
    send(self(), :connect)
    {:ok, nil}
  end

  def publish_message(message) do
    GenServer.call(__MODULE__, {:publish_message, message})
  end

  def get_connection do
    GenServer.call(__MODULE__, :get)
  end

  def handle_call(:get, _, conn) do
    {:reply, conn, conn}
  end

  def handle_call({:publish_message, message}, _from, conn) do
    {:ok, channel} = AMQP.Channel.open(conn)

    AMQP.Basic.publish(
      channel,
      @exchange_name,
      "#{@queue_name}.outbound",
      Jason.encode!(message)
    )

    {:reply, conn, conn}
  end

  def handle_info(:connect, _conn) do
    case Connection.open(@host) do
      {:ok, conn} ->
        # Get notifications when the connection goes down
        Process.monitor(conn.pid)
        {:noreply, conn}

      {:error, _} ->
        Logger.error("Failed to connect #{@host}. Reconnecting later...")
        # Retry later
        Process.send_after(self(), :connect, @reconnect_interval)
        {:noreply, nil}
    end
  end

  def handle_info({:DOWN, _, :process, _pid, reason}, _) do
    # Stop GenServer. Will be restarted by Supervisor.
    {:stop, {:connection_lost, reason}, nil}
  end
end

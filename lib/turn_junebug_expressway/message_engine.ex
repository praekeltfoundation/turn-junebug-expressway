defmodule TurnJunebugExpressway.MessageEngine do
  use GenServer
  use AMQP

  require Logger
  alias AMQP.Connection

  alias TurnJunebugExpresswayWeb.Utils

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

  def get_channel do
    GenServer.call(__MODULE__, :get)
  end

  def handle_call(:get, _, channel) do
    {:reply, channel, channel}
  end

  def handle_call({:publish_message, message}, _from, channel) do
    queue_name = Utils.get_env(:rabbitmq, :messages_queue)

    AMQP.Basic.publish(
      channel,
      Utils.get_env(:rabbitmq, :exchange_name),
      "#{queue_name}.outbound",
      Jason.encode!(message)
    )

    {:reply, channel, channel}
  end

  def handle_info(:connect, _channel) do
    username = Utils.get_env(:rabbitmq, :username)
    password = Utils.get_env(:rabbitmq, :password)
    host = Utils.get_env(:rabbitmq, :host)
    port = Utils.get_env(:rabbitmq, :port)
    vhost = Utils.get_env(:rabbitmq, :vhost)

    case Connection.open(
           host: host,
           username: username,
           password: password,
           port: port,
           virtual_host: vhost
         ) do
      {:ok, conn} ->
        # Get notifications when the connection goes down
        Process.monitor(conn.pid)

        {:ok, channel} = AMQP.Channel.open(conn)

        queue_name = Utils.get_env(:rabbitmq, :messages_queue)
        AMQP.Queue.declare(channel, "#{queue_name}.event")
        {:ok, _consumer_tag} = Basic.consume(channel, "#{queue_name}.event")

        {:noreply, channel}

      {:error, error} ->
        Logger.error("Failed to connect #{host}. Reconnecting later...")
        Logger.error("Error: #{error}")
        # Retry later
        Process.send_after(self(), :connect, @reconnect_interval)
        {:noreply, nil}
    end
  end

  def handle_info({:DOWN, _, :process, _pid, reason}, _) do
    # Stop GenServer. Will be restarted by Supervisor.
    {:stop, {:connection_lost, reason}, nil}
  end

  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, chan) do
    {:stop, :normal, chan}
  end

  def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}}, chan) do
    consume(chan, tag, redelivered, payload)
    {:noreply, chan}
  end

  defp consume(channel, tag, redelivered, payload) do
    :ok =
      case Utils.forward_event(payload) do
        :ok ->
          Basic.ack(channel, tag)

        {:error, status, reason} ->
          IO.puts("Error sending event: #{status} -> #{reason}")
          Basic.reject(channel, tag, requeue: not redelivered)
      end
  rescue
    _exception ->
      :ok = Basic.reject(channel, tag, requeue: not redelivered)
      IO.puts("Error with #{payload}")
  end
end

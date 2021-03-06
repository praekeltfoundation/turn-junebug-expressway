defmodule TurnJunebugExpressway.HttpPushEngine do
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

  def get_channel do
    GenServer.call(__MODULE__, :get)
  end

  def handle_call(:get, _, channel) do
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
        Process.flag(:trap_exit, true)

        {:ok, channel} = AMQP.Channel.open(conn)

        queue_name = Utils.get_env(:rabbitmq, :messages_queue)
        queue_concurrency = Utils.get_env(:rabbitmq, :queue_concurrency)
        exchange_name = Utils.get_env(:rabbitmq, :exchange_name)

        # Declare a exchange for testing
        case Mix.env() do
          :test ->
            AMQP.Exchange.declare(channel, exchange_name)

          _ ->
            nil
        end

        # Consume events queue
        Queue.declare(channel, "#{queue_name}.event", durable: true)

        Queue.bind(channel, "#{queue_name}.event", exchange_name,
          routing_key: "#{queue_name}.event"
        )

        :ok = Basic.qos(channel, prefetch_count: queue_concurrency)

        {:ok, _consumer_tag} = AMQP.Basic.consume(channel, "#{queue_name}.event", nil)

        # Consume inbound queue
        Queue.declare(channel, "#{queue_name}.inbound", durable: true)

        Queue.bind(channel, "#{queue_name}.inbound", exchange_name,
          routing_key: "#{queue_name}.inbound"
        )

        {:ok, _consumer_tag} = AMQP.Basic.consume(channel, "#{queue_name}.inbound", nil)

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

  def handle_info({:EXIT, _pid, reason}, _) do
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

  def ack_processed_msg(channel, tag) do
    Basic.ack(channel, tag)
  end

  def reject_failed_msg(channel, tag, redelivered, status, reason) do
    Basic.reject(channel, tag, requeue: not redelivered)

    msg = "Error sending event: #{status} -> #{reason}"

    case redelivered do
      false -> IO.puts(msg)
      true -> raise msg
    end
  end

  def start_consume_message_task(channel, tag, redelivered, payload) do
    case Task.ExpressSupervisor
         |> Task.Supervisor.async(fn ->
           TurnJunebugExpressway.ConsumeMessageTask.process_msg(payload)
         end)
         |> Task.await() do
      :ok ->
        ack_processed_msg(channel, tag)

      {:error, status, reason} ->
        reject_failed_msg(
          channel,
          tag,
          redelivered,
          status,
          reason
        )
    end
  end

  defp consume(channel, tag, redelivered, payload) do
    spawn(fn ->
      start_consume_message_task(channel, tag, redelivered, payload)
    end)
  end
end

defmodule TurnJunebugExpressway.ConsumeMessageTask do
  use Task

  alias TurnJunebugExpresswayWeb.Utils

  def start_link() do
    Task.start_link(ConsumeMessageTask, :run, [])
  end

  def process_msg(payload) do
    Utils.handle_incoming_event(payload)
  end
end

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
end

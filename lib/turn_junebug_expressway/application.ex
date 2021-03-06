defmodule TurnJunebugExpressway.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Metrics
    TurnJunebugExpresswayWeb.PhoenixInstrumenter.setup()
    TurnJunebugExpresswayWeb.PipelineInstrumenter.setup()
    TurnJunebugExpresswayWeb.MetricsPlugExporter.setup()

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(TurnJunebugExpresswayWeb.Endpoint, []),
      # Start your own worker by calling: TurnJunebugExpressway.Worker.start_link(arg1, arg2, arg3)
      # worker(TurnJunebugExpressway.Worker, [arg1, arg2, arg3]),
      worker(TurnJunebugExpressway.MessageEngine, []),
      worker(TurnJunebugExpressway.HttpPushEngine, []),
      {Task.Supervisor, name: Task.ExpressSupervisor, restart: :transient}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TurnJunebugExpressway.Supervisor]

    {:ok, _} = Logger.add_backend(Sentry.LoggerBackend)

    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TurnJunebugExpresswayWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

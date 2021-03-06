defmodule TurnJunebugExpressway.Mixfile do
  use Mix.Project

  def project do
    [
      app: :turn_junebug_expressway,
      version: "0.0.18",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.json": :test,
        "coveralls.detail": :test,
        credo: :test
      ],
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {TurnJunebugExpressway.Application, []},
      extra_applications: [:logger, :runtime_tools, :jason, :sentry]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4"},
      {:phoenix_pubsub, "~> 1.1"},
      {:ecto_sql, "~> 3.0"},
      {:phoenix_ecto, "~> 4.0"},
      {:postgrex, ">= 0.15.0"},
      {:gettext, "~> 0.17.1"},
      {:prometheus_phoenix, "~> 1.3.0"},
      {:prometheus_plugs, "~> 1.1.5"},
      {:prometheus_process_collector, "~> 1.6.0"},
      {:plug_cowboy, "~> 2.1"},
      {:jason, "~> 1.1"},
      {:amqp, "~> 1.3"},
      {:timex, "~> 3.5"},
      {:tesla, "~> 1.2"},
      {:mock, "~> 0.3.2"},
      {:mox, "~> 0.5", only: :test},
      {:sentry, "~> 7.2"},

      # Dev/test/build tools.
      {:excoveralls, "~> 0.8", only: :test},
      {:credo, "~> 0.9", only: [:dev, :test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["test"]
    ]
  end
end

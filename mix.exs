defmodule Peque.MixProject do
  use Mix.Project

  def project do
    [
      app: :peque,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      docs: docs(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Peque.Application, []}
    ]
  end

  defp aliases() do
    [
      # don't start application in tests
      # test: "test --no-start"
    ]
  end

  defp docs() do
    [
      main: Peque,
      groups_for_modules: [
        behaviours: [
          Peque.Queue,
          Peque.Storage
        ],
        genservers: [
          Peque.QueueServer,
          Peque.StorageServer
        ],
        queues: [
          Peque.FastQueue,
          Peque.QueueClient,
          Peque.PersistentQueue
        ],
        storages: [
          Peque.DETSStorage,
          Peque.StorageClient
        ]
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.4", only: :dev, runtime: false},
      {:benchee, "~> 0.11", only: :dev},
      {:benchee_html, "~> 0.4", only: :dev},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end

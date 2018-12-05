defmodule Peque.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Peque.Queue.Fast, as: QFast
  alias Peque.Queue.Persistent, as: QPersistent
  alias Peque.Queue.Worker, as: QWorker

  alias Peque.Storage.Client, as: SClient
  alias Peque.Storage.DETS, as: SDETS
  alias Peque.Storage.Worker, as: SWorker

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {SWorker, storage_opts()},
      {QWorker, queue_opts()}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_all, name: Peque.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp storage_opts do
    [
      name: SWorker,
      storage_mod: SDETS,
      storage_fn: &storage_fn/0
    ]
  end

  defp queue_opts do
    [
      name: QWorker,
      queue_mod: QPersistent,
      queue_fn: &queue_fn/0
    ]
  end

  defp storage_fn do
    {:ok, dets} = :dets.open_file(Peque.DETS, file: "peque.dets" |> String.to_charlist())
    SDETS.new(dets)
  end

  defp queue_fn do
    dump = SClient.dump(SWorker)

    internal_queue =
      %QFast{}
      |> QFast.init(dump)
      |> elem(1)

    %QPersistent{
      queue_mod: Peque.Queue.Fast,
      queue: internal_queue,
      storage_pid: Peque.Storage.Worker
    }
  end
end

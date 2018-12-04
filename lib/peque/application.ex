defmodule Peque.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Peque.StorageServer, storage_opts()},
      {Peque.QueueServer, queue_opts()}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_all, name: Peque.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp storage_opts do
    [
      name: Peque.StorageServer,
      storage_mod: Peque.DETSStorage,
      storage_fn: &storage_fn/0
    ]
  end

  defp queue_opts do
    [
      name: Peque.QueueServer,
      queue_mod: Peque.PersistentQueue,
      queue_fn: &queue_fn/0
    ]
  end

  defp storage_fn do
    {:ok, dets} = :dets.open_file(Peque.DETS, file: "peque.dets" |> String.to_charlist())
    Peque.DETSStorage.new(dets)
  end

  defp queue_fn do
    dump = Peque.StorageClient.dump(Peque.StorageServer)

    internal_queue =
      %Peque.FastQueue{}
      |> Peque.FastQueue.init(dump)
      |> elem(1)

    %Peque.PersistentQueue{
      queue_mod: Peque.FastQueue,
      queue: internal_queue,
      storage_pid: Peque.StorageServer
    }
  end
end

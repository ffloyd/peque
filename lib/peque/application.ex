defmodule Peque.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {
        Peque.StorageServer,
        [
          name: Peque.StorageServer,
          init_fun: fn ->
            {:ok, dets} = :dets.open_file(Peque.DETS, file: "peque.dets" |> String.to_charlist())
            storage = Peque.DETSStorage.new(dets)

            {Peque.DETSStorage, storage}
          end
        ]
      },
      {
        Peque.QueueServer,
        [
          name: Peque.QueueServer,
          init_fun: fn ->
            dump = Peque.StorageClient.dump(Peque.StorageServer)

            internal_queue =
              %Peque.FastQueue{}
              |> Peque.FastQueue.init(dump)
              |> elem(1)

            queue = %Peque.PersistentQueue{
              queue_mod: Peque.FastQueue,
              queue: internal_queue,
              storage_pid: Peque.StorageServer
            }

            {Peque.PersistentQueue, queue}
          end
        ]
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_all, name: Peque.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

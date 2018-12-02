defmodule Peque.PersistentQueueTest do
  use ExUnit.Case

  @dets_file "#{System.tmp_dir() || "."}/peque-dets-storage.dets"

  setup do
    start_supervised!(%{
      id: Peque.StorageServer,
      start:
        {GenServer, :start_link,
         [
           Peque.StorageServer,
           fn ->
             {:ok, dets} = :dets.open_file(Peque.DETS, file: @dets_file |> String.to_charlist())
             {Peque.DETSStorage, Peque.DETSStorage.new(dets)}
           end,
           [name: Peque.StorageServer]
         ]}
    })

    on_exit(fn ->
      File.rm(@dets_file)
    end)

    :ok
  end

  use Peque.QueueSharedTest,
    module: Peque.PersistentQueue,
    queue: %Peque.PersistentQueue{
      queue_mod: Peque.FastQueue,
      queue: %Peque.FastQueue{},
      storage_pid: Peque.StorageServer
    }
end

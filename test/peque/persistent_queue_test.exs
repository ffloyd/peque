defmodule Peque.PersistentQueueTest do
  use ExUnit.Case

  import Support.Helpers
  import Support.Shared

  alias Peque.FastQueue
  alias Peque.PersistentQueue
  alias Peque.StorageClient
  alias Peque.StorageServer

  setup_all do
    {:ok, _} =
      StorageServer.start_link(
        name: StorageServer.Test,
        storage_mod: Peque.DETSStorage,
        storage_fn: fn ->
          Peque.DETSStorage.new(make_dets!(StorageServer.Test, "storage"))
        end
      )

    on_exit(fn ->
      StorageServer.Test |> StorageClient.clear()
    end)
  end

  behaves_like_queue PersistentQueue do
    %PersistentQueue{
      queue_mod: FastQueue,
      queue: %FastQueue{},
      storage_pid: StorageServer.Test
    }
  end
end

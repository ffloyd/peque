defmodule Peque.PersistentQueueTest do
  use ExUnit.Case

  import Support.Helpers
  import Support.Shared

  behaves_like_queue Peque.PersistentQueue do
    dets = make_dets!(Peque.DETSStorage.DETS, "storage")

    pid =
      start_supervised!(
        {Peque.StorageServer,
         [
           storage_mod: Peque.DETSStorage,
           storage_fn: fn ->
             Peque.DETSStorage.new(dets)
           end
         ]}
      )

    %Peque.PersistentQueue{
      queue_mod: Peque.FastQueue,
      queue: %Peque.FastQueue{},
      storage_pid: pid
    }
  end
end

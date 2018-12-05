defmodule Peque.Queue.PersistentTest do
  use ExUnit.Case

  import Support.Helpers
  import Support.Shared

  alias Peque.Queue.Fast
  alias Peque.Queue.Persistent
  alias Peque.Storage.Client, as: SClient
  alias Peque.Storage.DETS, as: SDETS
  alias Peque.Storage.Worker, as: SWorker

  setup_all do
    {:ok, _} =
      SWorker.start_link(
        name: Storage.Worker.Test,
        storage_mod: SDETS,
        storage_fn: fn ->
          SDETS.new(make_dets!(Storage.Worker.Test, "storage"))
        end
      )

    on_exit(fn ->
      Storage.Worker.Test |> SClient.clear()
    end)
  end

  behaves_like_queue Persistent do
    %Persistent{
      queue_mod: Fast,
      queue: %Fast{},
      storage_pid: Storage.Worker.Test
    }
  end
end

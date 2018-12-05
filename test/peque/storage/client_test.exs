defmodule Peque.Storage.ClientTest do
  use ExUnit.Case

  import Support.Helpers
  import Support.Shared

  behaves_like_storage Peque.Storage.Client do
    dets = make_dets!(Peque.Storage.DETS.DETS, "storage")

    start_supervised!(
      {Peque.Storage.Worker,
       [storage_mod: Peque.Storage.DETS, storage_fn: fn -> Peque.Storage.DETS.new(dets) end]}
    )
  end
end

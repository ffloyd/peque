defmodule Peque.StorageClientTest do
  use ExUnit.Case

  import Support.Helpers
  import Support.Shared

  behaves_like_storage Peque.StorageClient do
    dets = make_dets!(Peque.DETSStorage.DETS, "storage")

    start_supervised!(
      {Peque.StorageServer, fn -> {Peque.DETSStorage, Peque.DETSStorage.new(dets)} end}
    )
  end
end

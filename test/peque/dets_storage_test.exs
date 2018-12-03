defmodule Peque.DETSStorageTest do
  use ExUnit.Case

  import Support.Helpers
  import Support.Shared

  behaves_like_storage Peque.DETSStorage do
    dets = make_dets!(Peque.DETSStorage.DETS, "storage")

    Peque.DETSStorage.new(dets)
  end
end

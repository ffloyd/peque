defmodule Peque.Storage.DETSTest do
  use ExUnit.Case

  import Support.Helpers
  import Support.Shared

  behaves_like_storage Peque.Storage.DETS do
    dets = make_dets!(Peque.Storage.DETS.DETS, "storage")

    Peque.Storage.DETS.new(dets)
  end
end

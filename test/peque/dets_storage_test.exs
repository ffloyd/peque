defmodule Peque.DETSStorageTest do
  use ExUnit.Case

  @dets_file "#{System.tmp_dir() || "."}/peque-dets-storage.dets"

  alias Peque.DETSStorage, as: Storage

  setup do
    on_exit(fn ->
      File.rm(@dets_file)
    end)

    :ok
  end

  test "works" do
    {:ok, dets} = :dets.open_file(Peque.DETS, file: @dets_file |> String.to_charlist())
    s = %Storage{dets: dets}

    s =
      s
      |> Storage.insert({2, "222"})
      |> Storage.insert({3, "333"})
      |> Storage.insert({5, "555"})
      |> Storage.insert({{50, :ack}, "505050"})

    assert Storage.get(s, 2) == {2, "222"}
    assert Storage.get(s, {50, :ack}) == {{50, :ack}, "505050"}
    assert Storage.min_id(s) == 2
    assert Storage.max_id(s) == 5
    assert Storage.max_ack_id(s) == 50
  end
end

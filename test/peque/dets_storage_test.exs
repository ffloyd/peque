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
    s = Storage.new(dets)

    s =
      s
      |> Storage.append("222")
      |> Storage.append("333")
      |> Storage.append("555")
      |> Storage.pop()
      |> Storage.add_ack(50, "505050")
      |> Storage.del_ack(50)
      |> Storage.set_next_ack_id(20)
      |> Storage.sync()

    assert Storage.next_ack_id(s) == 20
    assert :ok = Storage.close(s)
  end
end

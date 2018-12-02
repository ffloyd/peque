defmodule Peque.WALTest do
  use ExUnit.Case

  alias Peque.FastQueue
  alias Peque.Queue
  alias Peque.WAL

  test "populate via add/2 and sync to FastQueue via sync/2" do
    %WAL{queue: q} =
      %WAL{queue: %FastQueue{}}
      |> WAL.add({:add, "msg1"})
      |> WAL.add({:add, "msg2"})
      |> WAL.add(:get)
      |> WAL.add(:get)
      |> WAL.add({:ack, 1})
      |> WAL.add({:reject, 2})
      |> WAL.sync()

    assert {:ok, q, _, "msg2"} = Queue.get(q)
    assert {:empty, _} = Queue.get(q)
  end
end

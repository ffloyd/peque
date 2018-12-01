defmodule Peque.DetsQueueTest do
  use ExUnit.Case

  alias Peque.DetsQueue, as: PDQ
  alias Peque.Queue, as: Q

  @test_file "#{System.tmp_dir() || "."}/peque_test.dets"

  setup do
    on_exit(fn ->
      File.rm(@test_file)
    end)

    :ok
  end

  use Peque.QueueSharedTest, queue: Peque.DetsQueue.new(Peque.DETS, @test_file)

  test "new/2 correctly restores state" do
    q = PDQ.new(Peque.DETS, @test_file)

    {:ok, q} = Q.add(q, "msg1")
    {:ok, q} = Q.add(q, "msg2")
    {:ok, q, 1, "msg1"} = Q.get(q)

    PDQ.close(q)

    q = PDQ.new(Peque.DETS, @test_file)

    {:ok, q} = Q.ack(q, 1)
    {:ok, q, 2, "msg2"} = Q.get(q)
    {:empty, _} = Q.get(q)
  end

  test "sync/1 works" do
    q = PDQ.new(Peque.DETS, @test_file)
    :ok = PDQ.sync(q)
  end
end

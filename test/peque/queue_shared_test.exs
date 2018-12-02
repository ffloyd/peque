defmodule Peque.QueueSharedTest do
  alias Peque.Queue, as: Q

  defmacro __using__(queue: queue) do
    quote do
      describe "queue behaviour" do
        setup do
          %{queue: unquote(queue)}
        end

        test "success path: add/2 -> get/1 -> ack/2", %{queue: q} do
          assert {:ok, q} = Q.add(q, "msg")
          assert {:ok, q, ack_id = 1, "msg"} = Q.get(q)
          assert {:ok, q} = Peque.Queue.ack(q, ack_id)
        end

        test "success path: add/2 -> get/1 -> reject/2 -> get/1", %{queue: q} do
          assert {:ok, q} = Q.add(q, "msg")
          assert {:ok, q, ack_id = 1, "msg"} = Q.get(q)
          assert {:ok, q} = Q.reject(q, ack_id)
          assert {:ok, q, ack_id = 2, "msg"} = Q.get(q)
        end

        test "get/1 when empty", %{queue: q} do
          assert {:empty, _} = Q.get(q)
        end

        test "ack/2 when empty", %{queue: q} do
          assert {:not_found, q} = Q.ack(q, 1)
        end

        test "reject/2 when empty", %{queue: q} do
          assert {:not_found, q} = Q.reject(q, 1)
        end

        test "sync/1 when empty", %{queue: q} do
          assert {:ok, q} = Q.sync(q)
        end

        test "close/1 when empty", %{queue: q} do
          assert :ok = Q.close(q)
        end
      end
    end
  end
end

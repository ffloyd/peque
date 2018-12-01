defmodule Peque.QueueSharedTest do
  alias Peque.Queue, as: Q

  defmacro __using__(queue: queue) do
    quote do
      setup do
        %{queue: unquote(queue)}
      end

      test "success path: add/2 -> get/1 -> ack/2", %{queue: q} do
        {:ok, q} = Q.add(q, "msg")
        {:ok, q, ack_id = 1, "msg"} = Q.get(q)
        {:ok, q} = Peque.Queue.ack(q, ack_id)
      end

      test "success path: add/2 -> get/1 -> reject/2 -> get/1", %{queue: q} do
        {:ok, q} = Q.add(q, "msg")
        {:ok, q, ack_id = 1, "msg"} = Q.get(q)
        {:ok, q} = Q.reject(q, ack_id)
        {:ok, q, ack_id = 2, "msg"} = Q.get(q)
      end

      test "get/1 when empty", %{queue: q} do
        {:empty, _} = Q.get(q)
      end

      test "ack/2 when empty", %{queue: q} do
        {:not_found, q} = Q.ack(q, 1)
      end

      test "reject/2 when empty", %{queue: q} do
        {:not_found, q} = Q.reject(q, 1)
      end
    end
  end
end

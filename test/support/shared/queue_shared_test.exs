defmodule Peque.QueueSharedTest do
  defmacro __using__(mod: mod, do: expression) do
    quote location: :keep do
      defp __queue_setup(_context) do
        queue = unquote(expression)

        %{q: queue}
      end

      alias unquote(mod), as: Q

      describe "add/2, get/1" do
        setup :__queue_setup

        test "add and get two elements", %{q: q} do
          assert {:ok, q} = Q.add(q, "msg1")
          assert {:ok, q} = Q.add(q, "msg2")

          assert {:ok, q, 1, "msg1"} = Q.get(q)
          assert {:ok, q, 2, "msg2"} = Q.get(q)
        end

        test "get on empty queue", %{q: q} do
          assert :empty == Q.get(q)
        end
      end

      describe "add/2, get/1, ack/2" do
        setup :__queue_setup

        test "one message", %{q: q} do
          assert {:ok, q} = Q.add(q, "msg")
          assert {:ok, q, ack_id = 1, "msg"} = Q.get(q)

          assert {:ok, q, "msg"} = Q.ack(q, ack_id)
          assert :empty = Q.get(q)
        end
      end

      describe "add/2, get/1, reject/2" do
        setup :__queue_setup

        test "one message", %{q: q} do
          assert {:ok, q} = Q.add(q, "msg")
          assert {:ok, q, ack_id = 1, "msg"} = Q.get(q)

          assert {:ok, q, "msg"} = Q.reject(q, ack_id)

          assert {:ok, _, 2, "msg"} = Q.get(q)
        end
      end

      describe "sync/1" do
        setup :__queue_setup

        test "works on empty queue", %{q: q} do
          assert {:ok, _} = Q.sync(q)
        end
      end

      describe "close/1" do
        setup :__queue_setup

        test "works on empty queue", %{q: q} do
          assert :ok = Q.close(q)
        end
      end

      describe "empty?/1, add/2, get/1" do
        setup :__queue_setup

        test "on empty queue", %{q: q} do
          assert true == Q.empty?(q)
        end

        test "on non-empty queue", %{q: q} do
          {:ok, q} = Q.add(q, "msg")

          assert false == Q.empty?(q)
        end

        test "on empty queue with non-acked messages", %{q: q} do
          assert {:ok, q} = Q.add(q, "msg")
          assert {:ok, q, _, _} = Q.get(q)

          assert false == Q.empty?(q)
        end
      end

      describe "set_next_ack_id/1, add/2, get/1" do
        setup :__queue_setup

        test "default next ack_id is 1", %{q: q} do
          assert {:ok, q} = Q.add(q, "msg")
          assert {:ok, q} = Q.add(q, "msg")

          assert {:ok, q, 1, "msg"} = Q.get(q)
          assert {:ok, q, 2, "msg"} = Q.get(q)
        end

        test "sets next ack_id on empty queue", %{q: q} do
          assert {:ok, q} = Q.set_next_ack_id(q, 10)

          assert {:ok, q} = Q.add(q, "msg")
          assert {:ok, q} = Q.add(q, "msg")

          assert {:ok, q, 10, "msg"} = Q.get(q)
          assert {:ok, q, 11, "msg"} = Q.get(q)
        end

        test "returns :error on non-empty queue", %{q: q} do
          assert {:ok, q} = Q.add(q, "msg")
          assert :error == Q.set_next_ack_id(q, 10)
        end

        test "returns :error on empty queue with non-acked messages", %{q: q} do
          assert {:ok, q} = Q.add(q, "msg")
          assert {:ok, q, _, _} = Q.get(q)

          assert :error == Q.set_next_ack_id(q, 10)
        end
      end

      describe "init/2, get/1, ack/1" do
        setup :__queue_setup

        test "empty dump on empty queue", %{q: q} do
          dump = {[], %{}, 1}
          {:ok, q} = Q.init(q, dump)

          assert :empty = Q.get(q)
        end

        test "dump with data on empty queue", %{q: q} do
          dump = {["msg1", "msg2"], %{10 => "msg0"}, 11}

          {:ok, q} = Q.init(q, dump)

          assert {:ok, q, 11, "msg1"} = Q.get(q)
          assert {:ok, q, 12, "msg2"} = Q.get(q)
          assert :empty = Q.get(q)

          assert {:ok, q, "msg0"} = Q.ack(q, 10)
        end

        test "init when non-empty queue", %{q: q} do
          {:ok, q} = Q.add(q, "msg")

          assert :error = Q.init(q, {[], %{}, 1})
        end
      end
    end
  end
end

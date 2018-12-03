defmodule Peque.StorageSharedTest do
  defmacro __using__(mod: mod, do: expression) do
    quote location: :keep do
      alias unquote(mod), as: S

      defp __storage_setup(_context) do
        storage = unquote(expression)

        %{s: storage}
      end

      describe "append/2, first/1" do
        setup :__storage_setup

        test "add one message", %{s: s} do
          s = S.append(s, "msg")

          assert {:ok, "msg"} == S.first(s)
        end

        test "add two messages", %{s: s} do
          s =
            s
            |> S.append("msg1")
            |> S.append("msg2")

          assert {:ok, "msg1"} == S.first(s)
        end
      end

      describe "append/2, pop/1, first/1" do
        setup :__storage_setup

        test "add and pop two messages", %{s: s} do
          s =
            s
            |> S.append("msg1")
            |> S.append("msg2")
            |> S.pop()
            |> S.pop()

          assert :empty = S.first(s)
        end
      end

      describe "add_ack/3, del_ack/2, get_ack/2" do
        setup :__storage_setup

        test "add entry", %{s: s} do
          s = S.add_ack(s, 10, "msg")

          assert {:ok, "msg"} == S.get_ack(s, 10)
        end

        test "delete entry", %{s: s} do
          s =
            s
            |> S.add_ack(10, "msg")
            |> S.del_ack(10)

          assert :not_found == S.get_ack(s, 10)
        end
      end

      describe "sync/1" do
        setup :__storage_setup

        test "on empty storage", %{s: s} do
          assert S.sync(s)
        end
      end

      describe "close/1" do
        setup :__storage_setup

        test "on empty storage", %{s: s} do
          assert :ok = S.close(s)
        end
      end

      describe "dump/1, append/2, add_ack/3, set_next_ack_id/2" do
        setup :__storage_setup

        test "when empty", %{s: s} do
          assert {[], %{}, 1} == S.dump(s)
        end

        test "when not empty", %{s: s} do
          s =
            s
            |> S.append("msg1")
            |> S.append("msg2")
            |> S.add_ack(10, "msg0")
            |> S.set_next_ack_id(11)

          assert {["msg1", "msg2"], %{10 => "msg0"}, 11} == S.dump(s)
        end
      end
    end
  end
end

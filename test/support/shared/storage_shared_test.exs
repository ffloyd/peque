defmodule Peque.StorageSharedTest do
  defmacro __using__(mod: mod, do: expression) do
    quote do
      alias unquote(mod), as: S

      defp __storage_setup(_context) do
        storage = unquote(expression)

        %{s: storage}
      end

      describe "append/2" do
        setup :__storage_setup

        test "one message", %{s: s} do
          s = S.append(s, "msg")

          assert {:ok, "msg"} == S.first(s)
        end

        test "two messages", %{s: s} do
          s =
            s
            |> S.append("msg1")
            |> S.append("msg2")

          assert {:ok, "msg1"} == S.first(s)
        end
      end
    end
  end
end

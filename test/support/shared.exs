shared_path = Path.expand("shared", __DIR__)

{:ok, shared_tests} = File.ls(shared_path)
Enum.each(shared_tests, &Code.require_file(&1, shared_path))

defmodule Support.Shared do
  @moduledoc """
  Macroses for shared tests
  """

  defmacro behaves_like_queue(mod, do: expression) do
    quote do
      use Peque.QueueSharedTest, mod: unquote(mod), do: unquote(expression)
    end
  end

  defmacro behaves_like_storage(mod, do: expression) do
    quote do
      use Peque.StorageSharedTest, mod: unquote(mod), do: unquote(expression)
    end
  end
end

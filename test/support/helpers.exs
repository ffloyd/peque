defmodule Support.Helpers do
  @moduledoc """
  Helpers for `ExUnit` tests.

  Examples:

      defmodule Peque.PersistentQueueTest do
        use ExUnit.Case
        import Support.Helpers

        setup do
          %{dets: make_dets()}
        end
        
        ...
      end
  """

  alias ExUnit.Callbacks

  def file_for_dets(suffix) do
    file = "#{System.tmp_dir() || "."}/peque-#{suffix}.dets"

    File.rm(file)

    Callbacks.on_exit(fn ->
      File.rm(file)
    end)

    file
  end

  def make_dets!(name, suffix \\ "test") do
    filename =
      suffix
      |> file_for_dets()
      |> String.to_charlist()

    {:ok, ref} = :dets.open_file(name, file: filename)

    ref
  end
end

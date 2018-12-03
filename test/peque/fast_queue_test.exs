defmodule Peque.FastQueueTest do
  use ExUnit.Case, async: true

  import Support.Shared

  doctest Peque.FastQueue

  behaves_like_queue Peque.FastQueue do
    %Peque.FastQueue{}
  end
end

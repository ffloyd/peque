defmodule Peque.Queue.FastTest do
  use ExUnit.Case, async: true

  import Support.Shared

  doctest Peque.Queue.Fast

  behaves_like_queue Peque.Queue.Fast do
    %Peque.Queue.Fast{}
  end
end

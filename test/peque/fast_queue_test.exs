defmodule Peque.FastQueueTest do
  use ExUnit.Case, async: true

  doctest Peque.FastQueue

  use Peque.QueueSharedTest, queue: %Peque.FastQueue{}
end

defmodule Peque.FastQueueTest do
  use ExUnit.Case, async: true

  doctest Peque.FastQueue

  use Peque.QueueSharedTest, module: Peque.FastQueue, queue: %Peque.FastQueue{}
end

defmodule Peque.FastQueueTest do
  use ExUnit.Case, async: true

  use Peque.QueueSharedTest, queue: %Peque.FastQueue{}
end

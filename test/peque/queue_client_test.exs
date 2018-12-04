defmodule Peque.QueueClientTest do
  use ExUnit.Case

  import Support.Shared

  behaves_like_queue Peque.QueueClient do
    start_supervised!(
      {Peque.QueueServer, [queue_mod: Peque.FastQueue, queue_fn: fn -> %Peque.FastQueue{} end]}
    )
  end
end

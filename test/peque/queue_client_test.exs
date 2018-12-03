defmodule Peque.QueueClientTest do
  use ExUnit.Case

  import Support.Shared

  behaves_like_queue Peque.QueueClient do
    start_supervised!({Peque.QueueServer, fn -> {Peque.FastQueue, %Peque.FastQueue{}} end})
  end
end

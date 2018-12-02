defmodule Peque.QueueClientTest do
  use ExUnit.Case

  setup do
    start_supervised!(%{
      id: Peque.QueueServer,
      start:
        {GenServer, :start_link,
         [
           Peque.QueueServer,
           fn -> {Peque.FastQueue, %Peque.FastQueue{}} end,
           [name: Peque.QueueServer]
         ]}
    })

    :ok
  end

  use Peque.QueueSharedTest, module: Peque.QueueClient, queue: Peque.QueueServer
end

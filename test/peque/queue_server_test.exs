defmodule Peque.QueueServerTest do
  use ExUnit.Case

  setup do
    start_supervised!(%{
      id: Peque.QueueServer,
      start:
        {GenServer, :start_link,
         [Peque.QueueServer, %Peque.FastQueue{}, [name: Peque.QueueServer]]}
    })

    :ok
  end

  use Peque.QueueSharedTest, queue: Peque.QueueServer
end

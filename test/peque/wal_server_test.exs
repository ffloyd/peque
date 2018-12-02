defmodule Peque.WALServerTest do
  use ExUnit.Case

  test "populate via add/2 and sync to FastQueue via sync/2" do
    start_supervised!(%{
      id: Peque.QueueServer,
      start:
        {GenServer, :start_link, [Peque.QueueServer, %Peque.FastQueue{}, [name: QueueServer]]}
    })

    start_supervised!(%{
      id: Peque.WALServer,
      start:
        {GenServer, :start_link,
         [Peque.WALServer, %Peque.WAL{queue: QueueServer}, [name: WALServer]]}
    })

    GenServer.cast(WALServer, {:add, "msg1"})
    GenServer.cast(WALServer, {:add, "msg2"})
    GenServer.cast(WALServer, :get)
    GenServer.cast(WALServer, :get)
    GenServer.cast(WALServer, {:ack, 1})
    GenServer.cast(WALServer, {:reject, 2})
    GenServer.call(WALServer, :sync)

    assert {:ok, q, _, "msg2"} = Peque.Queue.get(QueueServer)
    assert {:empty, _} = Peque.Queue.get(QueueServer)
  end
end

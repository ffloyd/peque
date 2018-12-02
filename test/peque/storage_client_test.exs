defmodule Peque.StorageClientTest do
  use ExUnit.Case

  @dets_file "#{System.tmp_dir() || "."}/peque-dets-storage.dets"

  alias Peque.StorageClient, as: Storage

  setup do
    start_supervised!(%{
      id: Peque.StorageServer,
      start:
        {GenServer, :start_link,
         [
           Peque.StorageServer,
           fn ->
             {:ok, dets} = :dets.open_file(Peque.DETS, file: @dets_file |> String.to_charlist())
             {Peque.DETSStorage, Peque.DETSStorage.new(dets)}
           end,
           [name: Peque.StorageServer]
         ]}
    })

    on_exit(fn ->
      File.rm(@dets_file)
    end)

    :ok
  end

  test "works" do
    Peque.StorageServer
    |> Storage.append("222")
    |> Storage.append("333")
    |> Storage.append("555")
    |> Storage.pop()
    |> Storage.add_ack(50, "505050")
    |> Storage.del_ack(50)
    |> Storage.set_next_ack_id(20)
    |> Storage.sync()

    assert Storage.next_ack_id(Peque.StorageServer) == 20
    assert :ok = Storage.close(Peque.StorageServer)
  end
end

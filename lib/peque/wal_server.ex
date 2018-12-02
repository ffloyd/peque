defmodule Peque.WALServer do
  @moduledoc "WAL GenServer"

  use GenServer

  alias Peque.WAL

  @impl true
  @spec init(WAL.t()) :: {:ok, WAL.t()}
  def init(wal) do
    {:ok, wal}
  end

  @impl true
  @spec handle_cast(WAL.entry(), WAL.t()) :: WAL.t()
  def handle_cast(entry, wal) do
    {:noreply, WAL.add(wal, entry)}
  end

  @impl true
  def handle_call(:sync, _from, wal) do
    {:reply, :ok, WAL.sync(wal)}
  end
end

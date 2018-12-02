defmodule Peque.QueueClient do
  @moduledoc """
  `Peque.Queue` implementation for `Peque.QueueServer`.

  ## Examples

  Add and get message:

      {:ok, pid} = GenServer.start_link(Peque.QueueServer,
                                        fn ->
                                          {Peque.FastQueue, %Peque.FastQueue{}}
                                        end,
                                        name: Peque.QueueServer)

      {:ok, _} = Peque.Queue.add(pid, "message")
      {:ok, _, ack_id, message} = Peque.Queue.get(Peque.QueueServer)
  """

  @behaviour Peque.Queue

  def add(pid, message) do
    :ok = GenServer.call(pid, {:add, message})

    {:ok, pid}
  end

  def get(pid) do
    case GenServer.call(pid, :get) do
      {:ok, ack_id, message} -> {:ok, pid, ack_id, message}
      :empty -> {:empty, pid}
    end
  end

  def ack(pid, ack_id) do
    case GenServer.call(pid, {:ack, ack_id}) do
      :ok -> {:ok, pid}
      :not_found -> {:not_found, pid}
    end
  end

  def reject(pid, ack_id) do
    case GenServer.call(pid, {:reject, ack_id}) do
      :ok -> {:ok, pid}
      :not_found -> {:not_found, pid}
    end
  end

  def sync(pid) do
    :ok = GenServer.call(pid, :sync)

    {:ok, pid}
  end

  def close(pid) do
    GenServer.call(pid, :close)
  end

  def empty?(pid) do
    GenServer.call(pid, :empty?)
  end

  def set_next_ack_id(pid, next_ack_id) do
    case GenServer.call(pid, {:set_next_ack_id, next_ack_id}) do
      :ok -> {:ok, pid}
      :error -> :error
    end
  end
end

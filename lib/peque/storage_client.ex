defmodule Peque.StorageClient do
  @moduledoc """
  `Peque.Storage` implementation for `Peque.StorageServer`.
  """

  @behaviour Peque.Storage

  def append(pid, message) do
    :ok = GenServer.cast(pid, {:append, message})
    pid
  end

  def pop(pid) do
    :ok = GenServer.cast(pid, :pop)
    pid
  end

  def first(pid) do
    GenServer.call(pid, :first)
  end

  def add_ack(pid, ack_id, message) do
    :ok = GenServer.cast(pid, {:add_ack, ack_id, message})
    pid
  end

  def get_ack(pid, ack_id) do
    GenServer.call(pid, {:get_ack, ack_id})
  end

  def del_ack(pid, ack_id) do
    :ok = GenServer.cast(pid, {:del_ack, ack_id})
    pid
  end

  def next_ack_id(pid) do
    GenServer.call(pid, :next_ack_id)
  end

  def set_next_ack_id(pid, next_ack_id) do
    :ok = GenServer.cast(pid, {:set_next_ack_id, next_ack_id})
    pid
  end

  def sync(pid) do
    :ok = GenServer.call(pid, :sync)
    pid
  end

  def close(pid) do
    GenServer.call(pid, :close)
  end
end

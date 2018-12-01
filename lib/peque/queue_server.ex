defmodule Peque.QueueServer do
  @moduledoc "`GenServer` wrapper around `Peque.Queue`."

  use GenServer

  alias Peque.Queue

  @impl true
  def init(queue) do
    {:ok, queue}
  end

  @impl true
  def handle_call({:add, message}, _from, queue) do
    {:ok, queue} = Queue.add(queue, message)

    {:reply, :ok, queue}
  end

  @impl true
  def handle_call(:get, _from, queue) do
    case Queue.get(queue) do
      {:ok, queue, ack_id, message} -> {:reply, {:ok, ack_id, message}, queue}
      {:empty, queue} -> {:reply, :empty, queue}
    end
  end

  @impl true
  def handle_call({:ack, ack_id}, _from, queue) do
    case Queue.ack(queue, ack_id) do
      {:ok, queue} -> {:reply, :ok, queue}
      {:not_found, queue} -> {:reply, :not_found, queue}
    end
  end

  @impl true
  def handle_call({:reject, ack_id}, _from, queue) do
    case Queue.reject(queue, ack_id) do
      {:ok, queue} -> {:reply, :ok, queue}
      {:not_found, queue} -> {:reply, :not_found, queue}
    end
  end
end

defimpl Peque.Queue, for: [PID, Atom] do
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
end

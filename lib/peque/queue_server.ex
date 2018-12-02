defmodule Peque.QueueServer do
  @moduledoc """
  `GenServer` for `Peque.Queue` implementations.

  Executes `Peque.Queue.close/1` on `c:GenServer.terminate/2`.

  Requires queue builder as init argument.
  Also, there are `Peque.Queue` implementations for `t:pid/0` and `t:atom/0`:

      {:ok, pid} = GenServer.start_link(Peque.QueueServer, fn -> %Peque.FastQueue{} end,
                                        name: Peque.QueueServer)

      {:ok, _} = Peque.Queue.add(pid, "message")
      {:ok, _, ack_id, message} = Peque.Queue.get(Peque.QueueServer)
  """

  use GenServer

  alias Peque.Queue

  @impl true
  @spec init((() -> Queue.t())) :: {:ok, Queue.t()}
  def init(get_queue) do
    {:ok, get_queue.()}
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

  @impl true
  def handle_call(:sync, _from, queue) do
    {:ok, queue} = Queue.sync(queue)

    {:reply, :ok, queue}
  end

  @impl true
  def handle_call(:close, _from, queue) do
    :ok = Queue.close(queue)

    {:reply, :ok, queue, :hibernate}
  end

  @impl true
  def handle_call(:empty?, _from, queue) do
    {:reply, Queue.empty?(queue), queue}
  end

  @impl true
  def handle_call({:set_next_ack_id, next_ack_id}, _from, queue) do
    case Queue.set_next_ack_id(queue, next_ack_id) do
      {:ok, queue} -> {:reply, :ok, queue}
      :error -> {:reply, :error, queue}
    end
  end

  @impl true
  def terminate(_reason, queue) do
    Queue.close(queue)
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

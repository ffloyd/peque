defmodule Peque.QueueServer do
  @moduledoc """
  `GenServer` for `Peque.Queue` implementations.

  Executes `Peque.Queue.close/1` on `c:GenServer.terminate/2`.

  Requires queue builder as init argument.

  ## Examples

  Server for `Peque.FastQueue`:

      {:ok, pid} = GenServer.start_link(Peque.QueueServer,
                                        fn ->
                                          {Peque.FastQueue, %Peque.FastQueue{}}
                                        end,
                                        name: Peque.FastQueueServer)
  """

  use GenServer

  @type init_fun :: (() -> {atom(), Queue.t()})

  alias Peque.Queue

  @spec start_link(init_fun) :: GenServer.on_start()
  def start_link(init_fun) do
    GenServer.start_link(__MODULE__, init_fun)
  end

  @spec init(init_fun) :: {:ok, Queue.t()}
  def init(get_queue) do
    {:ok, get_queue.()}
  end

  def handle_call({:add, message}, _from, {mod, queue}) do
    {:ok, queue} = mod.add(queue, message)

    {:reply, :ok, {mod, queue}}
  end

  def handle_call(:get, _from, {mod, queue}) do
    case mod.get(queue) do
      {:ok, queue, ack_id, message} -> {:reply, {:ok, ack_id, message}, {mod, queue}}
      :empty -> {:reply, :empty, {mod, queue}}
    end
  end

  def handle_call({:ack, ack_id}, _from, {mod, queue}) do
    case mod.ack(queue, ack_id) do
      {:ok, queue, message} -> {:reply, {:ok, message}, {mod, queue}}
      :not_found -> {:reply, :not_found, {mod, queue}}
    end
  end

  def handle_call({:reject, ack_id}, _from, {mod, queue}) do
    case mod.reject(queue, ack_id) do
      {:ok, queue, message} -> {:reply, {:ok, message}, {mod, queue}}
      :not_found -> {:reply, :not_found, {mod, queue}}
    end
  end

  def handle_call(:sync, _from, {mod, queue}) do
    {:ok, queue} = mod.sync(queue)

    {:reply, :ok, {mod, queue}}
  end

  def handle_call(:close, _from, {mod, queue}) do
    :ok = mod.close(queue)

    {:reply, :ok, {mod, queue}, :hibernate}
  end

  def handle_call(:empty?, _from, {mod, queue}) do
    {:reply, mod.empty?(queue), {mod, queue}}
  end

  def handle_call({:set_next_ack_id, next_ack_id}, _from, {mod, queue}) do
    case mod.set_next_ack_id(queue, next_ack_id) do
      {:ok, queue} -> {:reply, :ok, {mod, queue}}
      :error -> {:reply, :error, {mod, queue}}
    end
  end

  def terminate(_reason, {mod, queue}) do
    mod.close(queue)
  end
end

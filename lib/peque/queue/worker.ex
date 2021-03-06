defmodule Peque.Queue.Worker do
  @moduledoc """
  `GenServer` for `Peque.Queue` implementations.

  Traps exits. Executes `c:Peque.Queue.sync/1` on `c:GenServer.terminate/2`.

  ## Examples

  Server for `Peque.Queue.Fast`:
       
      alias Peque.Queue.Fast
     
      {:ok, pid} = Peque.Queue.Worker.start_link(queue_mod: Fast, queue_fn: fn -> %Fast{} end)
  """

  use GenServer

  alias Peque.Queue

  @type options :: [option]
  @type option :: {:name, GenServer.name()} | {:queue_mod, module()} | {:queue_fn, queue_fn()}

  @type queue_fn :: (() -> Queue.t())

  @spec start_link(options()) :: GenServer.on_start()
  def start_link(opts) do
    name = Keyword.get(opts, :name)

    queue_mod = Keyword.fetch!(opts, :queue_mod)
    queue_fn = Keyword.fetch!(opts, :queue_fn)

    GenServer.start_link(__MODULE__, {queue_mod, queue_fn}, name: name)
  end

  @doc false
  def init({queue_mod, queue_fn}) do
    Process.flag(:trap_exit, true)
    {:ok, {queue_mod, queue_fn.()}}
  end

  def handle_call({:init, dump}, _from, {mod, queue}) do
    case mod.init(queue, dump) do
      {:ok, queue} -> {:reply, :ok, {mod, queue}}
      :error -> {:reply, :error, {mod, queue}}
    end
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

  def handle_call(:clear, _from, {mod, queue}) do
    {:ok, queue} = mod.clear(queue)

    {:reply, :ok, {mod, queue}}
  end

  def terminate(_reason, {mod, queue}) do
    mod.sync(queue)
  end
end

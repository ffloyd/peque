defmodule Peque.StorageServer do
  @moduledoc """
  `GenServer` wrapper for `Peque.Storage` implementations.

  ## Examples

  Server for `Peque.DETSStorage`:

      {:ok, pid} = Peque.StorageServer.start_link fn ->
                     {Peque.DETSStorage, Peque.DETSStorage.new(...)}
                   end
  """

  use GenServer

  @type options :: [option]
  @type option ::
          {:name, GenServer.name()} | {:storage_mod, module()} | {:storage_fn, storage_fn()}
  @type storage_fn :: (() -> Peque.Storage.t())

  @spec start_link(options()) :: GenServer.on_start()
  def start_link(opts) do
    name = Keyword.get(opts, :name)

    storage_mod = Keyword.fetch!(opts, :storage_mod)
    storage_fn = Keyword.fetch!(opts, :storage_fn)

    GenServer.start_link(__MODULE__, {storage_mod, storage_fn}, name: name)
  end

  def init({storage_mod, storage_fn}) do
    Process.flag(:trap_exit, true)
    {:ok, {storage_mod, storage_fn.()}}
  end

  def handle_info({:EXIT, _from, reason}, state) do
    {:stop, reason, state}
  end

  def handle_cast({:append, message}, {mod, storage}) do
    {:noreply, {mod, mod.append(storage, message)}}
  end

  def handle_cast(:pop, {mod, storage}) do
    {:noreply, {mod, mod.pop(storage)}}
  end

  def handle_cast({:add_ack, ack_id, message}, {mod, storage}) do
    {:noreply, {mod, mod.add_ack(storage, ack_id, message)}}
  end

  def handle_cast({:del_ack, ack_id}, {mod, storage}) do
    {:noreply, {mod, mod.del_ack(storage, ack_id)}}
  end

  def handle_cast({:set_next_ack_id, ack_id}, {mod, storage}) do
    {:noreply, {mod, mod.set_next_ack_id(storage, ack_id)}}
  end

  def handle_cast(:clear, {mod, storage}) do
    {:noreply, {mod, mod.clear(storage)}}
  end

  def handle_call(:next_ack_id, _from, {mod, storage}) do
    {:reply, mod.next_ack_id(storage), {mod, storage}}
  end

  def handle_call(:first, _from, {mod, storage}) do
    {:reply, mod.first(storage), {mod, storage}}
  end

  def handle_call({:get_ack, ack_id}, _from, {mod, storage}) do
    {:reply, mod.get_ack(storage, ack_id), {mod, storage}}
  end

  def handle_call(:sync, _from, {mod, storage}) do
    {:reply, :ok, {mod, mod.sync(storage)}}
  end

  def handle_call(:close, _from, {mod, storage}) do
    :ok = mod.close(storage)

    {:reply, :ok, {mod, storage}, :hibernate}
  end

  def handle_call(:dump, _from, {mod, storage}) do
    {:reply, mod.dump(storage), {mod, storage}}
  end

  def terminate(_reason, {mod, storage}) do
    mod.close(storage)
  end
end

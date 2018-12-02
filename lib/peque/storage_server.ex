defmodule Peque.StorageServer do
  @moduledoc """
  `GenServer` wrapper arond `Peque.Storage` implementations.
  """

  use GenServer

  @spec init((() -> {atom(), Peque.Storage.t()})) :: {:ok, {atom(), Peque.Storage.t()}}
  def init(init_fun) do
    {:ok, init_fun.()}
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

  def handle_call(:next_ack_id, _from, {mod, storage}) do
    {:reply, mod.next_ack_id(storage), {mod, storage}}
  end

  def handle_call(:sync, _from, {mod, storage}) do
    {:reply, :ok, {mod, mod.sync(storage)}}
  end

  def handle_call(:close, _from, {mod, storage}) do
    {:reply, :ok, {mod, mod.close(storage)}, :hibernate}
  end

  def terminate(_reason, {mod, storage}) do
    mod.close(storage)
  end
end
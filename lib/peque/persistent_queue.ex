defmodule Peque.PersistentQueue do
  @moduledoc """
  Persistent `Peque.Queue` implementation.

  Combines non-persistent `Peque.Queue` with `Peque.StorageServer` to provide persistance.
  """

  @behaviour Peque.Queue

  @enforce_keys [:queue_mod, :queue, :storage_pid]
  defstruct [:queue_mod, :queue, :storage_pid]

  alias Peque.StorageClient

  def add(pq = %{queue_mod: queue_mod, queue: queue, storage_pid: pid}, message) do
    {:ok, queue} = queue_mod.add(queue, message)

    StorageClient.append(pid, message)

    {:ok, %{pq | queue: queue}}
  end

  def get(pq = %{queue_mod: queue_mod, queue: queue, storage_pid: pid}) do
    case queue_mod.get(queue) do
      {:ok, queue, ack_id, message} ->
        StorageClient.pop(pid)
        StorageClient.add_ack(pid, ack_id, message)

        {:ok, %{pq | queue: queue}, ack_id, message}

      {:empty, _} ->
        {:empty, pq}
    end
  end

  def ack(pq = %{queue_mod: queue_mod, queue: queue, storage_pid: pid}, ack_id) do
    case queue_mod.ack(queue, ack_id) do
      {:ok, queue} ->
        StorageClient.del_ack(pid, ack_id)
        {:ok, %{pq | queue: queue}}

      {:not_found, _} ->
        {:not_found, pq}
    end
  end

  def reject(pq = %{queue_mod: queue_mod, queue: queue, storage_pid: pid}, ack_id) do
    case queue_mod.reject(queue, ack_id) do
      {:ok, queue} ->
        StorageClient.del_ack(pid, ack_id)
        # TODO: bug here
        {:ok, %{pq | queue: queue}}

      {:not_found, _} ->
        {:not_found, pq}
    end
  end

  def sync(pq = %{queue_mod: queue_mod, queue: queue, storage_pid: pid}) do
    {:ok, queue} = queue_mod.sync(queue)
    StorageClient.sync(pid)

    {:ok, %{pq | queue: queue}}
  end

  def close(%{queue_mod: queue_mod, queue: queue, storage_pid: pid}) do
    :ok = queue_mod.close(queue)
    :ok = StorageClient.close(pid)

    :ok
  end

  def empty?(%{queue_mod: queue_mod, queue: queue}) do
    queue_mod.empty?(queue)
  end

  def set_next_ack_id(pq = %{queue_mod: queue_mod, queue: queue, storage_pid: pid}, ack_id) do
    case queue_mod.set_next_ack_id(queue, ack_id) do
      {:ok, queue} ->
        StorageClient.set_next_ack_id(pid, ack_id)
        {:ok, %{pq | queue: queue}}

      :error ->
        :error
    end
  end
end
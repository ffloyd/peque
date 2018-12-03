defmodule Peque.PersistentQueue do
  @moduledoc """
  Persistent `Peque.Queue` implementation.

  Combines non-persistent `Peque.Queue` with `Peque.StorageServer` to provide persistance.

  ## Examples

  Initialization:

      internal_queue = %Peque.FastQueue{}
      {:ok, storage_server} = Peque.StorageServer.start_link(...) 

      queue = %Peque.PersistentQueue(
                queue_mod: Peque.FastQueue,
                queue: internal_queue,
                storage_pid: storage_server
              )
  """

  use Peque.Queue

  @enforce_keys [:queue_mod, :queue, :storage_pid]
  defstruct [:queue_mod, :queue, :storage_pid]

  alias Peque.StorageClient

  def init(pq, dump) do
    if empty?(pq) do
      {:ok,
       pq
       |> init_queue(dump)
       |> init_storage(dump)}
    else
      :error
    end
  end

  defp init_queue(pq = %{queue_mod: queue_mod, queue: queue}, dump) do
    {:ok, queue} = queue_mod.init(queue, dump)
    %{pq | queue: queue}
  end

  defp init_storage(pq = %{storage_pid: pid}, {queue_list, ack_map, next_ack_id}) do
    Enum.each(queue_list, &StorageClient.append(pid, &1))

    Enum.each(ack_map, fn {ack_id, msg} ->
      StorageClient.add_ack(pid, ack_id, msg)
    end)

    StorageClient.set_next_ack_id(pid, next_ack_id)

    pq
  end

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

      :empty ->
        :empty
    end
  end

  def ack(pq = %{queue_mod: queue_mod, queue: queue, storage_pid: pid}, ack_id) do
    case queue_mod.ack(queue, ack_id) do
      {:ok, queue, message} ->
        StorageClient.del_ack(pid, ack_id)
        {:ok, %{pq | queue: queue}, message}

      :not_found ->
        :not_found
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

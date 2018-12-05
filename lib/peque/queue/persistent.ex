defmodule Peque.Queue.Persistent do
  @moduledoc """
  Persistent `Peque.Queue` implementation.

  Combines non-persistent `Peque.Queue` with `Peque.Storage.Worker` to provide persistance.

  ## Examples

  Initialization:

      internal_queue = %Peque.Queue.Fast{}
      {:ok, storage_server} = Peque.Storage.Worker.start_link(...) 

      queue = %Peque.Queue.Persistent(
                queue_mod: Peque.Queue.Fast,
                queue: internal_queue,
                storage_pid: storage_server
              )
  """

  use Peque.Queue

  @enforce_keys [:queue_mod, :queue, :storage_pid]
  defstruct [:queue_mod, :queue, :storage_pid, ops: 0, ops_cast_limit: 500]

  alias Peque.Storage.Client, as: SClient

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
    Enum.each(queue_list, &SClient.append(pid, &1))

    Enum.each(ack_map, fn {ack_id, msg} ->
      SClient.add_ack(pid, ack_id, msg)
    end)

    SClient.set_next_ack_id(pid, next_ack_id)

    pq
  end

  def add(pq = %{queue_mod: queue_mod, queue: queue, storage_pid: pid}, message) do
    {:ok, queue} = queue_mod.add(queue, message)

    SClient.append(pid, message)

    {:ok, %{pq | queue: queue, ops: inc_ops(pq)}}
  end

  defp inc_ops(%{ops: ops, ops_cast_limit: ops, storage_pid: pid}) do
    SClient.ping(pid)
    0
  end

  defp inc_ops(%{ops: ops}), do: ops + 1

  def get(pq = %{queue_mod: queue_mod, queue: queue, storage_pid: pid}) do
    case queue_mod.get(queue) do
      {:ok, queue, ack_id, message} ->
        SClient.pop(pid)
        SClient.add_ack(pid, ack_id, message)

        {:ok, %{pq | queue: queue, ops: inc_ops(pq)}, ack_id, message}

      :empty ->
        :empty
    end
  end

  def ack(pq = %{queue_mod: queue_mod, queue: queue, storage_pid: pid}, ack_id) do
    case queue_mod.ack(queue, ack_id) do
      {:ok, queue, message} ->
        SClient.del_ack(pid, ack_id)
        {:ok, %{pq | queue: queue, ops: inc_ops(pq)}, message}

      :not_found ->
        :not_found
    end
  end

  def sync(pq = %{queue_mod: queue_mod, queue: queue, storage_pid: pid}) do
    {:ok, queue} = queue_mod.sync(queue)
    SClient.sync(pid)

    {:ok, %{pq | queue: queue}}
  end

  def empty?(%{queue_mod: queue_mod, queue: queue}) do
    queue_mod.empty?(queue)
  end

  def set_next_ack_id(
        pq = %{queue_mod: queue_mod, queue: queue, storage_pid: pid},
        ack_id
      ) do
    case queue_mod.set_next_ack_id(queue, ack_id) do
      {:ok, queue} ->
        SClient.set_next_ack_id(pid, ack_id)
        {:ok, %{pq | queue: queue, ops: inc_ops(pq)}}

      :error ->
        :error
    end
  end

  def clear(pq = %{queue_mod: queue_mod, queue: queue, storage_pid: pid}) do
    SClient.clear(pid)
    {:ok, queue} = queue_mod.clear(queue)

    {:ok, %{pq | queue: queue, ops: inc_ops(pq)}}
  end
end

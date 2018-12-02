defmodule Peque.WAL do
  @moduledoc "WAL log for queues."

  alias Peque.Queue

  defstruct [:queue, log: :queue.new]

  @type t :: %__MODULE__{queue: Queue.t(), log: :queue.queue(entry())}
  @type entry ::
          {:add, Queue.message()} | :get | {:ack, Queue.ack_id()} | {:reject, Queue.ack_id()}

  @spec add(t(), entry()) :: t()
  def add(wal = %{log: log}, entry) do
    %{wal | log: :queue.in(entry, log)}
  end

  @spec sync(t()) :: t()
  def sync(wal = %{queue: queue, log: log}) do
    updated_queue =
      log
      |> :queue.to_list()
      |> Enum.reduce(queue, &write(&1, &2))
      |> Queue.sync()
      |> elem(1)

    %{wal | queue: updated_queue, log: :queue.new}
  end

  @spec write(entry(), Queue.t()) :: Queue.t()
  defp write(entry, queue)

  defp write({:add, message}, queue) do
    queue |> Queue.add(message) |> elem(1)
  end

  defp write(:get, queue) do
    queue |> Queue.get() |> elem(1)
  end

  defp write({:ack, ack_id}, queue) do
    queue |> Queue.ack(ack_id) |> elem(1)
  end

  defp write({:reject, ack_id}, queue) do
    queue |> Queue.reject(ack_id) |> elem(1)
  end
end

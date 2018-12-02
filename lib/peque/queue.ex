defprotocol Peque.Queue do
  @moduledoc """
  This protocol describes what is queue.

  ## Examples

  Adding messages:

      {:ok, q} = Peque.Queue.add(q, "message")
      {:ok, q} = Peque.Queue.add(q, any: :term)
      
  Success message path:

      {:ok, q} = Peque.Queue.add(q, "message")
      {:ok, q, ack_id, "message"} = Peque.Queue.get(q)
      {:ok, q} = Peque.Queue.ack(q, ack_id)
  """

  @typedoc "Any erlang term allowed to be a message"
  @type message :: term()

  @typedoc "Reference which should be finalized via `ack/2` or `reject/2`"
  @type ack_id :: pos_integer()

  @doc """
  Add message to queue.

  Returns `{:ok, queue}`.
  """
  @spec add(t(), message()) :: {:ok, t()}
  def add(queue, message)

  @doc """
  Get message from queue.

  If queue is empty returns `{:empty, queue}`.
  Otherwise returns `{:ok, queue, ack_id, message}`.

  `ack_id` is not identifier of the message. It identifies particular `get/1` call in a context of `queue`.
  """
  @spec get(t()) :: {:ok, t(), ack_id(), message()} | {:empty, t()}
  def get(queue)

  @doc """
  Finalize message by `ack_id`.
  After this operation message completly removed from queue.

  Returns `{:ok, queue}` if unfinalized message with corresponding `ack_id` found.
  Otherwise returns `{:not_found, queue}`.
  """
  @spec ack(t(), ack_id()) :: {:ok, t()} | {:not_found, t()}
  def ack(queue, ack_id)

  @doc """
  Finalize message by `ack_id` and add it to `queue`.

  Returns `{:ok, queue}` if unfinalized message with corresponding `ack_id` found.
  Otherwise returns `{:not_found, queue}`.
  """
  @spec reject(t(), ack_id()) :: {:ok, t()} | {:not_found, t()}
  def reject(queue, ack_id)

  @doc """
  Sync queue data.

  For storage-based and similar queues writes all buffered data to the storage and syncs it.

  Returns `{:ok, queue}`
  """
  @spec sync(t()) :: {:ok, t()}
  def sync(queue)

  @doc """
  Sync and close queue. 

  After this operation queue should not be used.

  Returns `:ok`.
  """
  @spec close(t()) :: :ok
  def close(queue)
end

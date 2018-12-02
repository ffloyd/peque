defmodule Peque.Queue do
  @moduledoc """
  This behaviour describes what is queue.

  ## Examples

  Adding messages:

      {:ok, q} = Peque.FastQueue.add(q, "message")
      {:ok, q} = Peque.FastQueue.add(q, any: :term)
      
  Success message path:

      {:ok, q} = Peque.FastQueue.add(q, "message")
      {:ok, q, ack_id, "message"} = Peque.FastQueue.get(q)
      {:ok, q} = Peque.FastQueue.ack(q, ack_id)
  """

  @type t :: any()

  @typedoc "Any erlang term allowed to be a message"
  @type message :: term()

  @typedoc "Reference which should be finalized via `ack/2` or `reject/2`"
  @type ack_id :: pos_integer()

  @doc """
  Add message to queue.

  Returns `{:ok, queue}`.
  """
  @callback add(t(), message()) :: {:ok, t()}

  @doc """
  Get message from queue.

  If queue is empty returns `{:empty, queue}`.
  Otherwise returns `{:ok, queue, ack_id, message}`.

  `ack_id` is not identifier of the message. It identifies particular `get/1` call in a context of `queue`.
  """
  @callback get(t()) :: {:ok, t(), ack_id(), message()} | {:empty, t()}

  @doc """
  Finalize message by `ack_id`.
  After this operation message completly removed from queue.

  Returns `{:ok, queue}` if unfinalized message with corresponding `ack_id` found.
  Otherwise returns `{:not_found, queue}`.
  """
  @callback ack(t(), ack_id()) :: {:ok, t()} | {:not_found, t()}

  @doc """
  Finalize message by `ack_id` and add it to `queue`.

  Returns `{:ok, queue}` if unfinalized message with corresponding `ack_id` found.
  Otherwise returns `{:not_found, queue}`.
  """
  @callback reject(t(), ack_id()) :: {:ok, t()} | {:not_found, t()}

  @doc """
  Sync queue data.

  For storage-based and similar queues writes all buffered data to the storage and syncs it.

  Returns `{:ok, queue}`.
  """
  @callback sync(t()) :: {:ok, t()}

  @doc """
  Sync and close queue. 

  After this operation queue should not be used.

  Returns `:ok`.
  """
  @callback close(t()) :: :ok

  @doc """
  Returns `true` if `queue` is empty. `false` otherwise. 
  """
  @callback empty?(t()) :: boolean()

  @doc """
  Set next ack_id for empty queue.

  If `queue` isn't empty returns `:error`.

  Otherwise returns `{:ok, queue}`.
  """
  @callback set_next_ack_id(t(), ack_id()) :: {:ok, t()} | :error
end

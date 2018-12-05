defmodule Peque.Queue do
  @moduledoc """
  This behaviour describes what is queue.

  Provides default implementations for `c:reject/2`, `c:sync/1`, `c:close/1`.

  ## Examples

  Adding messages:

      {:ok, q} = Peque.Queue.Fast.add(q, "message")
      {:ok, q} = Peque.Queue.Fast.add(q, any: :term)
      
  Success message path:

      {:ok, q} = Peque.Queue.Fast.add(q, "message")
      {:ok, q, ack_id, "message"} = Peque.Queue.Fast.get(q)
      {:ok, q} = Peque.Queue.Fast.ack(q, ack_id)
  """

  @type t :: any()

  @typedoc "Any erlang term allowed to be a message"
  @type message :: term()

  @typedoc "Reference which should be finalized via `ack/2` or `reject/2`"
  @type ack_id :: pos_integer()

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour Peque.Queue

      def reject(q, ack_id) do
        case ack(q, ack_id) do
          {:ok, q, message} ->
            {:ok, q} = add(q, message)
            {:ok, q, message}

          :not_found ->
            :not_found
        end
      end

      def sync(q), do: {:ok, q}

      defoverridable reject: 2, sync: 1
    end
  end

  @doc """
  Init empty queue from `t:Peque.Storage.dump/0`.

  Returns `:error` if queue is not empty. Otherwise - `{:ok, queue}`.
  """
  @callback init(t(), Peque.Storage.dump()) :: {:ok, t()} | :error

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
  @callback get(t()) :: {:ok, t(), ack_id(), message()} | :empty

  @doc """
  Finalize message by `ack_id`.
  After this operation message completly removed from queue.

  Returns `{:ok, queue, message}` if unfinalized message with corresponding `ack_id` found.
  Otherwise returns `{:not_found, queue}`.
  """
  @callback ack(t(), ack_id()) :: {:ok, t(), message()} | :not_found

  @doc """
  Finalize message by `ack_id` and add it to `queue`.

  Returns `{:ok, queue, message}` if unfinalized message with corresponding `ack_id` found.
  Otherwise returns `{:not_found, queue}`.
  """
  @callback reject(t(), ack_id()) :: {:ok, t(), message()} | :not_found

  @doc """
  Sync queue data.

  For storage-based and similar queues writes all buffered data to the storage and syncs it.

  Returns `{:ok, queue}`.
  """
  @callback sync(t()) :: {:ok, t()}

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

  @doc """
  Resets queue to empty state.
  """
  @callback clear(t()) :: {:ok, t()}
end

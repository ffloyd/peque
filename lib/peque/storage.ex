defmodule Peque.Storage do
  @moduledoc """
  Defines API of storage suitable for queue persisting.
  """

  alias Peque.Queue

  @type t :: any()
  @type dump ::
          {[Queue.message()], %{optional(Queue.ack_id()) => Queue.message()}, Queue.ack_id()}

  @doc "Append one message to queue."
  @callback append(t(), Queue.message()) :: t()

  @doc "Pop message from queue."
  @callback pop(t()) :: t()

  @doc "Return first message in queue."
  @callback first(t()) :: {:ok, Queue.message()} | :empty

  @doc "Add ack waiter."
  @callback add_ack(t(), Queue.ack_id(), Queue.message()) :: t()

  @doc "Remove ack waiter."
  @callback del_ack(t(), Queue.ack_id()) :: t()

  @doc "Get a message behind ack_id."
  @callback get_ack(t(), Queue.ack_id()) :: {:ok, Queue.message()} | :not_found

  @doc "Get next_ack_id counter"
  @callback next_ack_id(t()) :: Queue.ack_id()

  @doc "Set next_ack_id counter"
  @callback set_next_ack_id(t(), Queue.ack_id()) :: t()

  @doc "Write all buffers to disk."
  @callback sync(t()) :: t()

  @doc "Close storage. Storage should not be used after closing."
  @callback close(t()) :: :ok

  @doc "Dump storage content to structure."
  @callback dump(t()) :: dump()

  @doc "Clear all storage content."
  @callback clear(t()) :: t()
end

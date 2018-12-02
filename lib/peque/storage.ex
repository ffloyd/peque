defmodule Peque.Storage do
  @moduledoc """
  Defines API of storage suitable for queue persisting.
  """

  alias Peque.Queue

  @type record :: {record_id(), Queue.message()}
  @type record_id :: id() | {Queue.ack_id(), :ack}
  @type id :: pos_integer()
  @type t :: any()

  @callback insert(t(), record()) :: t()

  @callback get(t(), record_id()) :: record() | :none

  @callback delete(t(), record_id()) :: t()

  @callback min_id(t()) :: id() | :none

  @callback max_id(t()) :: id() | :none

  @callback max_ack_id(t()) :: Queue.ack_id() | :none

  @callback sync(t()) :: t()

  @callback close(t()) :: :ok
end

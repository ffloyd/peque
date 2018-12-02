defprotocol Peque.Storage do
  @moduledoc """
  Defines API of storage suitable for queue persisting.
  """

  alias Peque.Queue

  @type record :: {record_id(), Queue.message()}
  @type record_id :: id() | {Queue.ack_id(), :ack}
  @type id :: pos_integer()

  @spec insert(t(), record()) :: t()
  def insert(storage, record)

  @spec get(t(), record_id()) :: record() | :none
  def get(storage, record_id)

  @spec delete(t(), record_id()) :: t()
  def delete(storage, record_id)

  @spec min_id(t()) :: id() | :none
  def min_id(storage)

  @spec max_id(t()) :: id() | :none
  def max_id(storage)

  @spec max_ack_id(t()) :: Queue.ack_id() | :none
  def max_ack_id(storage)

  @spec sync(t()) :: t()
  def sync(storage)

  @spec close(t()) :: :ok
  def close(storage)
end

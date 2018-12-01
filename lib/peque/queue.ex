defprotocol Peque.Queue do
  @type message :: term()
  @type ack_id :: pos_integer()
  
  @spec add(t(), message()) :: :ok | :error
  def add(queue, message)

  @spec get(t()) :: {:ok, ack_id(), message()} | :empty | :error
  def get(queue)

  @spec ack(t(), ack_id()) :: :ok | :not_found | :error
  def ack(queue, ack_id)

  @spec reject(t(), ack_id()) :: :ok | :not_found | :error
  def reject(queue, ack_id)
end

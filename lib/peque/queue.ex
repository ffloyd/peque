defprotocol Peque.Queue do
  @type message :: term()
  @type ack_id :: pos_integer()

  @spec add(t(), message()) :: {:ok, t()} | {:error, any(), t()}
  def add(queue, message)

  @spec get(t()) :: {:ok, t(), ack_id(), message()} | {:empty, t()} | {:error, any(), t()}
  def get(queue)

  @spec ack(t(), ack_id()) :: {:ok, t()} | {:not_found, t()} | {:error, any(), t()}
  def ack(queue, ack_id)

  @spec reject(t(), ack_id()) :: {:ok, t()} | {:not_found, t()} | {:error, any(), t()}
  def reject(queue, ack_id)
end

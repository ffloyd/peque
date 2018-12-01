defprotocol Peque.Queue do
  @type message :: term()
  @type ack_id :: pos_integer()

  @spec add(t(), message()) :: {:ok, t()} | {:error, t()}
  def add(queue, message)

  @spec get(t()) :: {:ok, t(), ack_id(), message()} | {:empty, t()} | {:error, t()}
  def get(queue)

  @spec ack(t(), ack_id()) :: {:ok, t()} | {:not_found, t()} | {:error, t()}
  def ack(queue, ack_id)

  @spec reject(t(), ack_id()) :: {:ok, t()} | {:not_found, t()} | {:error, t()}
  def reject(queue, ack_id)
end

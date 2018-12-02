defprotocol Peque.Queue do
  @type message :: term()
  @type ack_id :: pos_integer()

  @spec add(t(), message()) :: {:ok, t()}
  def add(queue, message)

  @spec get(t()) :: {:ok, t(), ack_id(), message()} | {:empty, t()}
  def get(queue)

  @spec ack(t(), ack_id()) :: {:ok, t()} | {:not_found, t()}
  def ack(queue, ack_id)

  @spec reject(t(), ack_id()) :: {:ok, t()} | {:not_found, t()}
  def reject(queue, ack_id)

  @spec sync(t()) :: {:ok, t()}
  def sync(queue)

  @spec close(t()) :: :ok
  def close(queue)
end

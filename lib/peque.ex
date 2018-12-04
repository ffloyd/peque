defmodule Peque do
  @moduledoc """
  Global persistent queue OTP Application.
  """

  alias Peque.Queue
  alias Peque.QueueClient
  alias Peque.QueueServer

  @doc """
  Add message to global queue.

  ## Examples

      iex> Peque.add("message")
      :ok
      
      iex> Peque.add(%{another: :type})
      :ok
  """
  @spec add(Queue.message()) :: :ok
  def add(message) do
    {:ok, _} = QueueClient.add(QueueServer, message)
    :ok
  end

  @doc """
  Get message and ack_id from global queue.

  Returns `{ack_id, message}` or `:empty`.
  """
  @spec get() :: {Queue.ack_id(), Queue.message()} | :empty
  def get do
    case QueueClient.get(QueueServer) do
      {:ok, _, ack_id, message} -> {ack_id, message}
      :empty -> :empty
    end
  end

  @doc """
  ACK message by `ack_id`.

  Returns `:ok` or `:not_found`.
  """
  @spec ack(Queue.ack_id()) :: :ok | :not_found
  def ack(ack_id) do
    case QueueClient.ack(QueueServer, ack_id) do
      {:ok, _, _} -> :ok
      :not_found -> :not_found
    end
  end

  @doc """
  REJECT: Ack message by `ack_id` and add it to queue.

  Returns `:ok` or `:not_found`.
  """
  @spec reject(Queue.ack_id()) :: :ok | :not_found
  def reject(ack_id) do
    case QueueClient.reject(QueueServer, ack_id) do
      {:ok, _, _} -> :ok
      :not_found -> :not_found
    end
  end

  @spec sync() :: :ok
  def sync() do
    {:ok, _} = QueueClient.sync(QueueServer)
    :ok
  end

  @spec clear() :: :ok
  def clear do
    {:ok, _} = QueueClient.clear(QueueServer)
    :ok
  end
end

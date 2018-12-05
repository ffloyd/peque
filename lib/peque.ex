defmodule Peque do
  @moduledoc """
  Global persistent queue client.

  Just a simple combination of `Peque.Queue.Client` and lightweight offensive api.
  """

  alias Peque.Queue
  alias Peque.Queue.Client
  alias Peque.Queue.Worker

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
    {:ok, _} = Worker |> Client.add(message)
    :ok
  end

  @doc """
  Get message and ack_id from global queue.

  Returns `{ack_id, message}` or `:empty`.
  """
  @spec get() :: {Queue.ack_id(), Queue.message()} | :empty
  def get do
    case Worker |> Client.get() do
      {:ok, _, ack_id, message} -> {ack_id, message}
      :empty -> :empty
    end
  end

  @doc """
  ACK message by `ack_id`.

  After this operation message completely removed from queue.

  Returns `:ok` or `:not_found`.
  """
  @spec ack(Queue.ack_id()) :: :ok | :not_found
  def ack(ack_id) do
    case Worker |> Client.ack(ack_id) do
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
    case Worker |> Client.reject(ack_id) do
      {:ok, _, _} -> :ok
      :not_found -> :not_found
    end
  end

  @doc """
  Sync queue data.
  """
  @spec sync() :: :ok
  def sync do
    {:ok, _} = Worker |> Client.sync()
    :ok
  end

  @doc """
  Clear whole queue and non-ACK'ed messages.
  """
  @spec clear() :: :ok
  def clear do
    {:ok, _} = Worker |> Client.clear()
    :ok
  end
end

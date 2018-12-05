defmodule Peque.Queue.Fast do
  @moduledoc """
  Fast in-memory `Peque.Queue` behaviour implementation.

  It uses Erlang's `:queue.new/0` for queueing and `Map` as storage for removed, but non-acked messages.

  ## Examples:

  Initialization:

      iex> %Peque.Queue.Fast{}
      %Peque.Queue.Fast{active: %{}, next_ack_id: 1, queue: {[], []}}
  """

  alias Peque.Queue

  defstruct queue: :queue.new(), active: %{}, next_ack_id: 1

  use Queue

  @type t :: %__MODULE__{
          queue: :queue.queue(Queue.message()),
          active: %{optional(Queue.ack_id()) => Queue.message()},
          next_ack_id: Queue.ack_id()
        }

  def init(state, {queue_list, ack_map, next_ack_id}) do
    if empty?(state) do
      {:ok,
       %__MODULE__{
         queue: :queue.from_list(queue_list),
         active: ack_map,
         next_ack_id: next_ack_id
       }}
    else
      :error
    end
  end

  def add(state = %{queue: q}, message) do
    {:ok, %{state | queue: :queue.in(message, q)}}
  end

  def get(state = %{queue: q, active: active, next_ack_id: ack_id}) do
    case :queue.out(q) do
      {:empty, _} ->
        :empty

      {{:value, message}, next_q} ->
        {
          :ok,
          %{
            state
            | queue: next_q,
              active: Map.put(active, ack_id, message),
              next_ack_id: ack_id + 1
          },
          ack_id,
          message
        }
    end
  end

  def ack(state = %{active: active}, ack_id) do
    case Map.fetch(active, ack_id) do
      {:ok, message} ->
        {
          :ok,
          %{state | active: Map.delete(active, ack_id)},
          message
        }

      :error ->
        :not_found
    end
  end

  def empty?(%{queue: q, active: active}), do: :queue.is_empty(q) && Enum.empty?(active)

  def set_next_ack_id(state, new_next_ack_id) do
    if empty?(state) do
      {:ok, %{state | next_ack_id: new_next_ack_id}}
    else
      :error
    end
  end

  def clear(_) do
    {:ok, %__MODULE__{}}
  end
end

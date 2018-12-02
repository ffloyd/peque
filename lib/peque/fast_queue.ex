defmodule Peque.FastQueue do
  @moduledoc """
  Fast in-memory `Peque.Queue` protocol implementation.

  It uses Erlang's `:queue` for queueing and `Map` as storage for removed, but non-acked messages.

  ## Examples:

  New queue:

      iex> %Peque.FastQueue{}
      %Peque.FastQueue{active: %{}, next_ack_id: 1, queue: {[], []}}
      
  New queue with preconfigured first ack_id:

      iex> %Peque.FastQueue{next_ack_id: 22}
      %Peque.FastQueue{active: %{}, next_ack_id: 22, queue: {[], []}}
  """

  alias Peque.Queue

  defstruct queue: :queue.new(), active: %{}, next_ack_id: 1

  @type t :: %__MODULE__{
          queue: :queue.queue(Queue.message()),
          active: %{optional(Queue.ack_id()) => Queue.message()},
          next_ack_id: Queue.ack_id()
        }

  defimpl Peque.Queue do
    def add(state = %{queue: q}, message) do
      {:ok, %{state | queue: :queue.in(message, q)}}
    end

    def get(state = %{queue: q, active: active, next_ack_id: ack_id}) do
      case :queue.out(q) do
        {:empty, _} ->
          {:empty, state}

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
        {:ok, _} ->
          {
            :ok,
            %{state | active: Map.delete(active, ack_id)}
          }

        :error ->
          {:not_found, state}
      end
    end

    def reject(state = %{queue: q, active: active}, ack_id) do
      case Map.fetch(active, ack_id) do
        {:ok, message} ->
          {
            :ok,
            %{state | queue: :queue.in(message, q), active: Map.delete(active, ack_id)}
          }

        :error ->
          {:not_found, state}
      end
    end

    def sync(state) do
      {:ok, state}
    end

    def close(_state) do
      :ok
    end
  end
end

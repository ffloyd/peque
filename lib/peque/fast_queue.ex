defmodule Peque.FastQueue do
  @moduledoc "Fast in-memory `Peque.Queue` implementation."

  defstruct queue: :queue.new(), active: %{}, next_ack_id: 1

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
  end
end

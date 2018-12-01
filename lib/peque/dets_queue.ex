defmodule Peque.DetsQueue do
  @moduledoc "DETS-backed persistent `Peque.Queue` implementation."

  defstruct [:dets, :left_id, :right_id]

  def new(dets_name, filename) do
    erl_filename = String.to_charlist(filename)
    {:ok, dets} = :dets.open_file(dets_name, file: erl_filename)

    {left_id, right_id} =
      case :dets.info(dets, :size) do
        0 -> dets_init(dets)
        _ -> dets_load(dets)
      end

    %__MODULE__{
      dets: dets,
      left_id: left_id,
      right_id: right_id
    }
  end

  defp dets_init(dets) do
    :ok = :dets.insert(dets, {:next_ack_id, 1})

    {1, 1}
  end

  defp dets_load(dets) do
    {left_id, before_right_id} =
      dets
      # :ets.fun2ms fn {id, _} when is_integer(id) -> id end
      |> :dets.select([{{:"$1", :_}, [is_integer: :"$1"], [:"$1"]}])
      |> Enum.min_max(fn -> {1, 1} end)

    right_id = before_right_id + 1

    {left_id, right_id}
  end

  def sync(%{dets: dets}) do
    :ok = :dets.sync(dets)
  end

  def close(%{dets: dets}) do
    :ok = :dets.close(dets)
  end

  defimpl Peque.Queue do
    def add(state = %{dets: dets, right_id: id}, message) do
      :ok = :dets.insert(dets, {id, message})

      {:ok, %{state | right_id: id + 1}}
    end

    def get(state = %{left_id: id, right_id: id}) do
      {:empty, state}
    end

    def get(state = %{dets: dets, left_id: id}) do
      [{_, ack_id}] = :dets.lookup(dets, :next_ack_id)
      :ok = :dets.insert(dets, {:next_ack_id, ack_id + 1})

      case :dets.lookup(dets, id) do
        [{^id, message}] ->
          :ok = :dets.delete(dets, id)

          :ok =
            :dets.insert(dets, [
              {{ack_id, :active}, message},
              {:next_ack_id, ack_id + 1}
            ])

          {
            :ok,
            %{state | left_id: id + 1},
            ack_id,
            message
          }

        [] ->
          {:empty, state}
      end
    end

    def ack(state = %{dets: dets}, ack_id) do
      case :dets.lookup(dets, {ack_id, :active}) do
        [{_, _}] ->
          :ok = :dets.delete(dets, {ack_id, :active})

          {:ok, state}

        [] ->
          {:not_found, state}
      end
    end

    def reject(state = %{dets: dets}, ack_id) do
      case :dets.lookup(dets, {ack_id, :active}) do
        [{_, message}] ->
          :ok = :dets.delete(dets, {ack_id, :active})
          add(state, message)

        [] ->
          {:not_found, state}
      end
    end
  end
end

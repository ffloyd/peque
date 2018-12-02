defmodule Peque.DETSStorage do
  @moduledoc """
  Simple DETS-based implementation of `Peque.Storage`.
  """

  defstruct [:dets]

  @type t :: %__MODULE__{dets: :dets.tab_name()}


  defimpl Peque.Storage do
    def insert(s, record) do
      :dets.insert(s.dets, record)
      s
    end

    def get(s, record_id) do
      case :dets.lookup(s.dets, record_id) do
        [record] -> record
        [] -> :none
      end
    end

    def delete(s, record_id) do
      :dets.delete(s.dets, record_id)
      s
    end

    def min_id(s) do
      s
      |> all_ids()
      |> Enum.min(fn -> :none end)
    end

    def max_id(s) do
      s
      |> all_ids()
      |> Enum.max(fn -> :none end)
    end

    def max_ack_id(s) do
      s
      |> all_ack_ids()
      |> Enum.max(fn -> :none end)
    end

    def sync(s) do
      :dets.sync(s.dets)
      s
    end

    def close(s) do
      :dets.close(s.dets)
      :ok
    end

    @spec all_ids(Peque.DETSStorage.t()) :: [Peque.Storage.id()]
    defp all_ids(s) do
      # matcher = :ets.fun2ms fn {x, _} when is_integer(x) -> x end
      matcher = [{{:"$1", :_}, [is_integer: :"$1"], [:"$1"]}]

      :dets.select(s.dets, matcher)
    end

    @spec all_ack_ids(Peque.DETSStorage.t()) :: [Peque.Queue.ack_id()]
    defp all_ack_ids(s) do
      # matcher = :ets.fun2ms fn {{x, :ack}, _} -> x end
      matcher = [{{{:"$1", :ack}, :_}, [], [:"$1"]}]

      :dets.select(s.dets, matcher)
    end
  end
end

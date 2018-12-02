defmodule Peque.DETSStorage do
  @moduledoc """
  Simple DETS-based implementation of `Peque.Storage`.
  """

  @enforce_keys [:dets]
  defstruct [:dets, min_id: 0, max_id: 0, next_ack_id: 0]

  @type t :: %__MODULE__{
          dets: :dets.tab_name(),
          min_id: pos_integer(),
          max_id: pos_integer(),
          next_ack_id: Peque.Queue.ack_id()
        }

  @behaviour Peque.Storage

  @spec new(:dets.tab_name()) :: t()
  def new(dets) do
    {min_id, max_id} =
      dets
      |> all_ids()
      |> Enum.min_max(fn -> {0, 0} end)

    max_ack_id =
      dets
      |> all_ack_ids()
      |> Enum.max(fn -> 0 end)

    next_ack_id =
      case :dets.lookup(dets, :next_ack_id) do
        [{:next_ack_id, ack_id}] -> ack_id
        _ -> 1
      end

    next_ack_id = max(next_ack_id, max_ack_id + 1)

    %__MODULE__{dets: dets, min_id: min_id, max_id: max_id, next_ack_id: next_ack_id}
  end

  @impl true
  def append(s = %{dets: dets, max_id: max_id}, message) do
    :ok = :dets.insert(dets, {max_id + 1, message})

    %{s | max_id: max_id + 1}
  end

  @impl true
  def pop(s = %{min_id: 0}), do: s

  @impl true
  def pop(s = %{dets: dets, min_id: min_id}) do
    :ok = :dets.delete(dets, min_id)

    %{s | min_id: min_id + 1}
  end

  @impl true
  def add_ack(s = %{dets: dets}, ack_id, message) do
    :ok = :dets.insert(dets, {{ack_id, :ack}, message})
    s
  end

  @impl true
  def del_ack(s = %{dets: dets}, ack_id) do
    :ok = :dets.delete(dets, {ack_id, :ack})
    s
  end

  @impl true
  def next_ack_id(%{next_ack_id: ack_id}), do: ack_id

  @impl true
  def set_next_ack_id(s = %{dets: dets}, next_ack_id) do
    :ok = :dets.insert(dets, {:next_ack_id, next_ack_id})

    %{s | next_ack_id: next_ack_id}
  end

  @impl true
  def sync(s) do
    :dets.sync(s.dets)
    s
  end

  @impl true
  def close(%{dets: dets}) do
    :dets.close(dets)
    :ok
  end

  @spec all_ids(:dets.tab_name()) :: [pos_integer()]
  defp all_ids(dets) do
    # matcher = :ets.fun2ms fn {x, _} when is_integer(x) -> x end
    matcher = [{{:"$1", :_}, [is_integer: :"$1"], [:"$1"]}]

    :dets.select(dets, matcher)
  end

  @spec all_ack_ids(:dets.tab_name()) :: [pos_integer()]
  defp all_ack_ids(dets) do
    # matcher = :ets.fun2ms fn {{x, :ack}, _} -> x end
    matcher = [{{{:"$1", :ack}, :_}, [], [:"$1"]}]

    :dets.select(dets, matcher)
  end
end

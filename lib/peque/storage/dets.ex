defmodule Peque.Storage.DETS do
  @moduledoc """
  Simple DETS-based implementation of `Peque.Storage`.

  It's very simple storage implementation.
  All functions relies directly on `:dets` and no custom buffering performed.

  Use `new/1` for initializing.
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

  @doc """
  Initializes storage.

  `dets` must be an reference of opened table returned from `:dets.open_file/2`.

  For new storage initialization merely use empty table.
  """
  @spec new(:dets.tab_name()) :: t()
  def new(dets) do
    {min_id, max_id} =
      dets
      |> all_ids()
      |> Enum.min_max(fn -> {1, 0} end)

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

  def append(s = %{dets: dets, max_id: max_id}, message) do
    :ok = :dets.insert(dets, {max_id + 1, message})

    %{s | max_id: max_id + 1}
  end

  def pop(s = %{dets: dets, min_id: min_id}) do
    :ok = :dets.delete(dets, min_id)

    %{s | min_id: min_id + 1}
  end

  def first(%{dets: dets, min_id: min_id}) do
    case :dets.lookup(dets, min_id) do
      [{^min_id, message}] -> {:ok, message}
      _ -> :empty
    end
  end

  def add_ack(s = %{dets: dets}, ack_id, message) do
    :ok = :dets.insert(dets, {{ack_id, :ack}, message})
    s
  end

  def get_ack(%{dets: dets}, ack_id) do
    case :dets.lookup(dets, {ack_id, :ack}) do
      [{{^ack_id, :ack}, message}] -> {:ok, message}
      _ -> :not_found
    end
  end

  def del_ack(s = %{dets: dets}, ack_id) do
    :ok = :dets.delete(dets, {ack_id, :ack})
    s
  end

  def next_ack_id(%{next_ack_id: ack_id}), do: ack_id

  def set_next_ack_id(s = %{dets: dets}, next_ack_id) do
    :ok = :dets.insert(dets, {:next_ack_id, next_ack_id})

    %{s | next_ack_id: next_ack_id}
  end

  def sync(s) do
    :dets.sync(s.dets)
    s
  end

  def close(%{dets: dets}) do
    :dets.close(dets)
    :ok
  end

  def dump(s = %{dets: dets}) do
    queue =
      dets
      # :ets.fun2ms fn msg = {id, _} when is_integer(id) -> msg end
      |> :dets.select([{{:"$1", :_}, [is_integer: :"$1"], [:"$_"]}])
      |> Enum.sort()
      |> Enum.map(&elem(&1, 1))

    ack_waiters =
      dets
      # :ets.fun2ms fn {{id, :ack}, msg} -> {id, msg} end
      |> :dets.select([{{{:"$1", :ack}, :"$2"}, [], [{{:"$1", :"$2"}}]}])
      |> Map.new()

    {queue, ack_waiters, next_ack_id(s)}
  end

  def clear(%{dets: dets}) do
    :ok = :dets.delete_all_objects(dets)

    new(dets)
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

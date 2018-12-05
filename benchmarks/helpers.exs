defmodule H do
  def message_gen(count) do
    1..count |> Enum.map(&"message #{&1}")
  end

  def fast_queue! do
    %Peque.Queue.Fast{}
  end

  def persistent_queue!(queue, mod, storage_pid) do
    %Peque.Queue.Persistent{
      queue_mod: mod,
      queue: queue,
      storage_pid: storage_pid
    }
  end

  def queue_server!(queue, mod) do
    {:ok, pid} =
      Peque.Queue.Worker.start_link(
        queue_mod: mod,
        queue_fn: fn -> queue end
      )

    pid
  end

  def dets_file do
    result = "#{System.tmp_dir() || "."}/benchmarks.dets" |> String.to_charlist()
    File.rm(result)
    result
  end

  def dets! do
    {:ok, dets} = :dets.open_file(Peque.Benchmark.DETS, file: dets_file())
    dets
  end

  def dets_storage(dets) do
    Peque.Storage.DETS.new(dets)
  end

  def storage_server!(storage, mod) do
    {:ok, pid} =
      Peque.Storage.Worker.start_link(
        storage_mod: mod,
        storage_fn: fn -> storage end
      )

    pid
  end
end

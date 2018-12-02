fast_queue = {Peque.FastQueue, %Peque.FastQueue{}}

{:ok, pid} = GenServer.start_link(Peque.QueueServer, fn -> fast_queue end)
fast_server_queue = {Peque.QueueClient, pid}

dets_file = "#{System.tmp_dir() || "."}/benchmarks_queues.dets" |> String.to_charlist()
File.rm(dets_file)

{:ok, dets} = :dets.open_file(Peque.Benchmark.Storage, file: dets_file)
dets_storage = {Peque.DETSStorage, Peque.DETSStorage.new(dets)}

{:ok, pid} = GenServer.start_link(Peque.StorageServer, fn -> dets_storage end)

persistent_queue =
  {Peque.PersistentQueue,
   %Peque.PersistentQueue{queue_mod: Peque.FastQueue, queue: %Peque.FastQueue{}, storage_pid: pid}}

{:ok, pid} = GenServer.start_link(Peque.QueueServer, fn -> persistent_queue end)
persistent_server_queue = {Peque.QueueClient, pid}

message_gen = fn x -> 1..x |> Enum.map(&"message #{&1}") end

add_get_ack = fn {mod, q} ->
  fn messages ->
    q =
      Enum.reduce(messages, q, fn msg, q ->
        {:ok, q} = mod.add(q, msg)

        q
      end)

    {q, ack_ids} =
      Enum.reduce(messages, {q, []}, fn _, {q, ack_ids} ->
        {:ok, q, ack_id, _} = mod.get(q)

        {q, [ack_id | ack_ids]}
      end)

    q =
      Enum.reduce(ack_ids, q, fn ack_id, q ->
        {:ok, q} = mod.ack(q, ack_id)

        q
      end)

    mod.sync(q)
  end
end

Benchee.run(
  %{
    "Fast: process N messages and sync" => add_get_ack.(fast_queue),
    "Fast (GenServer): process N messages and sync" => add_get_ack.(fast_server_queue),
    "Persistent: process N messages and sync" => add_get_ack.(persistent_queue),
    "Persistent (GenServer): process N messages and sync" => add_get_ack.(persistent_server_queue)
  },
  inputs: %{
    "1000 messages" => message_gen.(1_000),
    "10 messages" => message_gen.(10)
  },
  memory_time: 2,
  formatters: [
    Benchee.Formatters.Console,
    Benchee.Formatters.HTML
  ]
)

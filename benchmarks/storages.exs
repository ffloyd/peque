dets_file = "#{System.tmp_dir() || "."}/benchmarks_storages.dets" |> String.to_charlist()

File.rm(dets_file)

{:ok, dets} = :dets.open_file(Peque.Benchmark.Storage, file: dets_file)
dets_storage = {Peque.DETSStorage, Peque.DETSStorage.new(dets)}

{:ok, pid} = GenServer.start_link(Peque.StorageServer, fn -> dets_storage end)
dets_server_storage = {Peque.StorageClient, pid}

message_gen = fn x -> 1..x |> Enum.map(&"message #{&1}") end

append_pop_sync = fn {mod, q} ->
  fn messages ->
    q =
      Enum.reduce(messages, q, fn msg, q ->
        mod.append(q, msg)
      end)

    q =
      Enum.reduce(messages, q, fn _, q ->
        mod.pop(q)
      end)

    mod.sync(q)
  end
end

Benchee.run(
  %{
    "DETS: append N times then pop all & sync" => append_pop_sync.(dets_storage),
    "DETS (GenServer): append N times then pop all & sync" =>
      append_pop_sync.(dets_server_storage)
  },
  inputs: %{
    "10000 messages" => message_gen.(10_000),
    "10 messages" => message_gen.(10)
  },
  memory_time: 2,
  formatters: [
    Benchee.Formatters.Console,
    Benchee.Formatters.HTML
  ],
  formatter_options: [console: [extended_statistics: true]]
)

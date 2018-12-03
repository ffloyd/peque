"helpers.exs"
|> Path.expand(__DIR__)
|> Code.require_file()

append_pop_sync = fn mod, s ->
  fn messages ->
    s =
      Enum.reduce(messages, s, fn msg, s ->
        mod.append(s, msg)
      end)

    s =
      Enum.reduce(messages, s, fn _, s ->
        mod.pop(s)
      end)

    mod.sync(s)
  end
end

IO.puts("-------------------------------------------")
IO.puts("-  append all messages, pop all and sync  -")
IO.puts("-------------------------------------------")

dets_storage = H.dets_storage(H.dets!())
dets_server = H.storage_server!(dets_storage, Peque.DETSStorage)

Benchee.run(
  %{
    "Peque.DETSStorage" => append_pop_sync.(Peque.DETSStorage, dets_storage),
    "Peque.DETSStorage (behind GenServer)" => append_pop_sync.(Peque.StorageClient, dets_server)
  },
  inputs: %{
    "10 messages" => H.message_gen(10),
    "10000 messages" => H.message_gen(10_000)
  },
  memory_time: 2,
  formatters: [
    Benchee.Formatters.Console,
    Benchee.Formatters.HTML
  ],
  formatter_options: [html: [file: "benchmarks/output/storages.html", auto_open: false]]
)

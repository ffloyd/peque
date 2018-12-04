Peque.clear()

IO.puts("--------------------------------")
IO.puts("- Benchmark 4 parallel clients -")
IO.puts("--------------------------------")

Benchee.run(
  %{
    "1. Peque.add(\"message\")" => fn -> Peque.add("message") end,
    "2. Peque.get, Peque.ack" => fn ->
      {ack_id, _} = Peque.get()
      :ok = Peque.ack(ack_id)
    end
  },
  parallel: 4,
  print: [fast_warning: false]
)

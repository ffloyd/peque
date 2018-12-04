"helpers.exs"
|> Path.expand(__DIR__)
|> Code.require_file()

add_get_ack = fn mod, q ->
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

    Enum.reduce(ack_ids, q, fn ack_id, q ->
      {:ok, q, _} = mod.ack(q, ack_id)

      q
    end)
  end
end

peque_add_get_ack = fn messages ->
  Enum.each(messages, &Peque.add/1)

  messages
  |> Enum.map(fn _ -> elem(Peque.get(), 1) end)
  |> Enum.map(&Peque.ack/1)
end

IO.puts("-------------------------------------------")
IO.puts("-  add all messages, pop all and ack all  -")
IO.puts("-------------------------------------------")

fast_server = H.queue_server!(H.fast_queue!(), Peque.FastQueue)

# persistent_queue =
#   H.persistent_queue!(
#     H.fast_queue!(),
#     Peque.FastQueue,
#     H.dets!()
#     |> H.dets_storage()
#     |> H.storage_server!(Peque.DETSStorage)
#   )

# persistent_server = H.queue_server!(persistent_queue, Peque.PersistentQueue)

Peque.clear()

Benchee.run(
  %{
    "Peque" => peque_add_get_ack,
    "FastQueue" => add_get_ack.(Peque.FastQueue, H.fast_queue!()),
    "FastQueue (behind GenServer)" => add_get_ack.(Peque.QueueClient, fast_server)
    # "PersistentQueue" => add_get_ack.(Peque.PersistentQueue, persistent_queue),
    # "PersistentQueue (behind GenServer)" => add_get_ack.(Peque.QueueClient, persistent_server)
  },
  inputs: %{
    "10 000 messages" => H.message_gen(10_000),
    # "10 messages" => H.message_gen(10),
    "1 message" => H.message_gen(1)
  },
  time: 10,
  formatters: [
    Benchee.Formatters.Console,
    Benchee.Formatters.HTML
  ],
  print: [fast_warning: false],
  formatter_options: [html: [file: "benchmarks/output/queues.html", auto_open: false]]
)

Peque.clear()

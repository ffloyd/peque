alias Peque.Queue, as: Q

dets_file = "#{System.tmp_dir() || "."}/peque.dets"

File.rm(dets_file)

fast_queue = %Peque.FastQueue{}

{:ok, fast_server_queue} = GenServer.start_link(Peque.QueueServer, %Peque.FastQueue{})

message_gen = fn x -> 1..x |> Enum.map(&"message #{&1}") end

add_get_ack = fn q ->
  fn messages ->
    q =
      Enum.reduce(messages, q, fn msg, q ->
        {:ok, q} = Q.add(q, msg)

        q
      end)

    {q, ack_ids} =
      Enum.reduce(messages, {q, []}, fn _, {q, ack_ids} ->
        {:ok, q, ack_id, _} = Q.get(q)

        {q, [ack_id | ack_ids]}
      end)

    Enum.reduce(ack_ids, q, fn ack_id, q ->
      {:ok, q} = Q.ack(q, ack_id)

      q
    end)
  end
end

Benchee.run(
  %{
    "Fast: add, get then ack N times" => add_get_ack.(fast_queue),
    "Fast (GenServer): add, get then ack N times" => add_get_ack.(fast_server_queue)
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

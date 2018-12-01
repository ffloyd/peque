alias Peque.Queue, as: Q

dets_file = "#{System.tmp_dir() || "."}/peque.dets"

fast_queue = %Peque.FastQueue{}
dets_queue = Peque.DetsQueue.new(Peque.DETS, dets_file)

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
    "Fast: add/get/ack N times" => add_get_ack.(fast_queue),
    "DETS: add/get/ack N times" => add_get_ack.(dets_queue)
  },
  inputs: %{
    "10000 messages" => message_gen.(10_000),
    "1000 messages" => message_gen.(1000),
    "100 messages" => message_gen.(100)
  },
  after_scenario: fn _ ->
    :dets.close(dets_queue.dets)
    File.rm("peque.dets")
    Peque.DetsQueue.new(Peque.DETS, dets_file)
  end,
  memory_time: 2,
  formatters: [
    Benchee.Formatters.Console,
    Benchee.Formatters.HTML
  ],
  formatter_options: [console: [extended_statistics: true]]
)

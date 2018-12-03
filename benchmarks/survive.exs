IO.puts("-------------------------------------------------------")
IO.puts("-  10M strings, 10 min non-stop, 2 insane GenServers  -")
IO.puts("-------------------------------------------------------")

count = 10_000_000

Benchee.run(
  %{
    "10 000 000 messages add" => fn ->
      Enum.each(1..count, fn x ->
        Peque.add("message#{x}-#{DateTime.utc_now()}")
      end)

      ack_ids =
        Enum.map(1..count, fn _ ->
          Peque.get() |> elem(0)
        end)

      ack_ids
      |> Enum.map(&Peque.ack/1)
    end
  },
  time: 60 * 10,
  memory_time: 10
)

IO.puts("----------------------------------------------------------------")
IO.puts("-  10k x 16 strings, 2 insane GenServers, 16 parallel clients  -")
IO.puts("----------------------------------------------------------------")

count = 10_000

Peque.clear()

Benchee.run(
  %{
    "10 000 messages" => fn ->
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
  time: 60,
  memory_time: 5,
  parallel: 16
)

Peque.clear()

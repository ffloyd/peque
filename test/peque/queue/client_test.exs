defmodule Peque.Queue.ClientTest do
  use ExUnit.Case

  import Support.Shared

  behaves_like_queue Peque.Queue.Client do
    start_supervised!(
      {Peque.Queue.Worker, [queue_mod: Peque.Queue.Fast, queue_fn: fn -> %Peque.Queue.Fast{} end]}
    )
  end
end

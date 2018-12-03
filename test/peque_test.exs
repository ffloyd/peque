defmodule PequeTest do
  use ExUnit.Case

  setup do
    Peque.clear()
  end

  doctest Peque

  test "success path: add/1 -> get/0 -> ack/1" do
    assert :ok = Peque.add("msg")
    assert {ack_id, "msg"} = Peque.get()
    assert :ok = Peque.ack(ack_id)

    assert :empty = Peque.get()
  end

  test "semi-success path: add/1 -> get/0 -> reject/1 -> get/0 -> ack/1" do
    assert :ok = Peque.add("msg")
    assert {ack_id, "msg"} = Peque.get()
    assert :ok = Peque.reject(ack_id)

    assert {ack_id_2, "msg"} = Peque.get()
    refute ack_id == ack_id_2
    assert :ok = Peque.ack(ack_id_2)

    assert :empty = Peque.get()
  end
end

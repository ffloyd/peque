defmodule PequeTest do
  use ExUnit.Case
  doctest Peque

  test "greets the world" do
    assert Peque.hello() == :world
  end
end

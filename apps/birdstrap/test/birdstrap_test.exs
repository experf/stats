defmodule BirdstrapTest do
  use ExUnit.Case
  doctest Birdstrap

  test "greets the world" do
    assert Birdstrap.hello() == :world
  end
end

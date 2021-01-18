#!/usr/bin/env elixir

defmodule M do
  def f(id) when is_binary(id) and byte_size(id) > 0 do
    IO.puts "YES: #{inspect id}"
  end

  def f(id) do
    IO.puts "NO: #{inspect id}"
  end
end

M.f(1)
M.f("")
M.f("yo")

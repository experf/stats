defmodule Cortex.Types.Interval do
  @moduledoc ~S"""

  Adapted from [OvermindDL1/ecto_interval](
    https://github.com/OvermindDL1/ecto_interval
  ).

  In particular, this file commit:

  https://github.com/OvermindDL1/ecto_interval/blob/1d50db5941021d4c4d332049383ab16ad908525f/lib/ecto_interval.ex

  ## References

  1.  [Postgrex data types](
        https://hexdocs.pm/postgrex/readme.html#data-representation
      )
  2.  [Ecto data types](
        https://hexdocs.pm/ecto/Ecto.Schema.html#module-primitive-types
      )
  """
  use Ecto.Type

  @impl true
  def type, do: Postgrex.Interval

  @impl true
  def cast(%{"months" => months, "days" => days, "secs" => secs}) do
    do_cast(months, days, secs)
  end

  def cast(%{months: months, days: days, secs: secs}) do
    do_cast(months, days, secs)
  end

  def cast(_) do
    :error
  end

  defp do_cast(months, days, secs) do
    try do
      months = to_integer(months)
      days = to_integer(days)
      secs = to_integer(secs)
      {:ok, %{months: months, days: days, secs: secs}}
    rescue
      _ -> :error
    end
  end

  defp to_integer(arg) when is_binary(arg) do
    String.to_integer(arg)
  end

  defp to_integer(arg) when is_integer(arg) do
    arg
  end

  @impl true
  def load(%{months: months, days: days, secs: secs}) do
    {:ok, %Postgrex.Interval{months: months, days: days, secs: secs}}
  end

  @impl true
  def dump(%{months: months, days: days, secs: secs}) do
    {:ok, %Postgrex.Interval{months: months, days: days, secs: secs}}
  end

  def dump(%{"months" => months, "days" => days, "secs" => secs}) do
    {:ok, %Postgrex.Interval{months: months, days: days, secs: secs}}
  end
end

defimpl String.Chars, for: [Postgrex.Interval] do
  import Kernel, except: [to_string: 1]

  def to_string(%{:months => months, :days => days, :secs => secs}) do
    m =
      if months === 0 do
        ""
      else
        " #{months} months"
      end

    d =
      if days === 0 do
        ""
      else
        " #{days} days"
      end

    s =
      if secs === 0 do
        ""
      else
        " #{secs} seconds"
      end

    if months === 0 and days === 0 and secs === 0 do
      "<None>"
    else
      "Every#{m}#{d}#{s}"
    end
  end
end

defimpl Inspect, for: [Postgrex.Interval] do
  def inspect(inv, _opts) do
    inspect(Map.from_struct(inv))
  end
end

defimpl Phoenix.HTML.Safe, for: [Postgrex.Interval] do
  def to_iodata(inv) do
    to_string(inv)
  end
end

defmodule Cortex.Types.Interval do
  @moduledoc ~S"""

  Adapted from [OvermindDL1/ecto_interval][].

  [OvermindDL1/ecto_interval]: https://github.com/OvermindDL1/ecto_interval

  In particular, this file commit:

  https://github.com/OvermindDL1/ecto_interval/blob/1d50db5941021d4c4d332049383ab16ad908525f/lib/ecto_interval.ex

  ## References

  1.  [Postgrex data types](
        https://hexdocs.pm/postgrex/readme.html#data-representation
      )
  2.  [Ecto data types](
        https://hexdocs.pm/ecto/Ecto.Schema.html#module-primitive-types
      )
  3.  [Ecto custom type](
        https://hexdocs.pm/ecto/Ecto.Type.html
      )
  4.  [Postgrex.Interval](
        https://hexdocs.pm/postgrex/Postgrex.Interval.html
      )
  """
  require Logger

  use Ecto.Type

  @millisecs_per_sec 1_000
  @microsecs_per_sec 1_000_000

  @secs_per_min 60
  @mins_per_hours 60
  @secs_per_hour @secs_per_min * @mins_per_hours

  # We use this to normalize between underlying seconds and days, so that
  # `Postgrex.Interval.compare/2` works correctly. Yeah it's probably not always
  # true, daylight savings time and such, but whatever, it is for us. For now
  # at least.
  @hours_per_day 24
  @secs_per_day @hours_per_day * @secs_per_hour
  @microsecs_per_day @secs_per_day * @microsecs_per_sec

  # Helpers
  # ==========================================================================

  defp to_integer(""), do: 0

  defp to_integer(arg) when is_binary(arg) do
    String.to_integer(arg)
  end

  defp to_integer(arg) when is_integer(arg) do
    arg
  end

  def simplify(struct, src_key, dest_key, src_per_dest_ratio) do
    src_value = struct |> Map.get(src_key, 0)
    dest_value = struct |> Map.get(dest_key, 0)
    extra_dest = src_value |> div(src_per_dest_ratio)
    rem_src = src_value |> rem(src_per_dest_ratio)
    %{struct | src_key => rem_src, dest_key => dest_value + extra_dest}
  end

  def simplify(struct, conversions) when is_list(conversions) do
    conversions
    |> Enum.reduce(
      struct,
      fn {src_key, dest_key, src_per_dest_ratio}, struct ->
        struct |> simplify(src_key, dest_key, src_per_dest_ratio)
      end
    )
  end

  def simplify(struct) do
    struct
    |> simplify([
      {:microsecs, :secs, @microsecs_per_sec},
      {:secs, :days, @secs_per_day}
    ])
  end

  @doc ~S"""
  Get the string you want for any of the `Postgrex.Interval` struct keys.

  ## Examples

      iex> Cortex.Types.Interval.humanize(:mins)
      "Minutes"

  """
  @spec humanize(:days | :hours | :mins | :secs) :: binary
  def humanize(:days), do: "Days"
  def humanize(:hours), do: "Hours"
  def humanize(:mins), do: "Minutes"
  def humanize(:secs), do: "Seconds"

  @doc ~S"""
  Get a `Keyword` list for an interval simplified to days, hours, minutes and
  seconds (DHMS). Used to render form controls with those inputs.

  ## Examples

  1.  Basics

          iex> %Postgrex.Interval{secs: 60} |> Cortex.Types.Interval.to_dhms()
          {:ok, [days: 0, hours: 0, mins: 1, secs: 0]}

          iex> %Postgrex.Interval{secs: 3_600} |> Cortex.Types.Interval.to_dhms()
          {:ok, [days: 0, hours: 1, mins: 0, secs: 0]}

          iex> %Postgrex.Interval{secs: 15_599} |> Cortex.Types.Interval.to_dhms()
          {:ok, [days: 0, hours: 4, mins: 19, secs: 59]}

  2.  Heads up — `days` is it's own field! `to_dhms/1` will **_not_** simplify
      large amounts of seconds into `days` for you:

          iex> %Postgrex.Interval{secs: 172_800} |> Cortex.Types.Interval.to_dhms()
          {:ok, [days: 0, hours: 48, mins: 0, secs: 0]}

      This is because, in practice, it doesn't need to — `cast/1` handles that
      business in the application flow.

  3.  `nil` is accepted:

          iex> nil |> Cortex.Types.Interval.to_dhms()
          {:ok, [days: 0, hours: 0, mins: 0, secs: 0]}

  4.  We don't try to convert `months`:

          iex> %Postgrex.Interval{months: 1} |> Cortex.Types.Interval.to_dhms()
          {:error, "Can not convert to DHMS -- months and microsecs must both be 0"}

  5.  We also have nothing to do with `microsecs`, so that's prohibited as well:

          iex> %Postgrex.Interval{microsecs: 1} |> Cortex.Types.Interval.to_dhms()
          {:error, "Can not convert to DHMS -- months and microsecs must both be 0"}

  6.  Anything that is _not_ a `Postgrex.Interval` struct will be attempted to
      be `cast/1` first:

          iex> %{"secs" => "172800"} |> Cortex.Types.Interval.to_dhms()
          {:ok, [days: 2, hours: 0, mins: 0, secs: 0]}

      You'll notice that this time, seconds _was_ simplified to days due to the
      map being passed through `cast/1`.

      > 📢 We need this functionality because — for reason I can't really pin
      > down at the moment — the params map ends up being used as the value to
      > render when there are multiple intervals being rendered on a page _and_
      > one of them fails to validate.
      >
      > It's the _other_ interval that ends up here as a `%{string => string}`
      > map. Whatever, it works.
  """
  def to_dhms(value)

  def to_dhms(nil), do: {:ok, [days: 0, hours: 0, mins: 0, secs: 0]}

  def to_dhms(%Postgrex.Interval{
        months: 0,
        days: days,
        secs: secs,
        microsecs: 0
      }) do
    {:ok,
     [
       days: days,
       hours: secs |> div(@secs_per_hour),
       mins: secs |> rem(@secs_per_hour) |> div(@secs_per_min),
       secs: secs |> rem(@secs_per_min)
     ]}
  end

  def to_dhms(%Postgrex.Interval{} = _),
    do:
      {:error, "Can not convert to DHMS -- months and microsecs must both be 0"}

  def to_dhms(value) do
    case cast(value) do
      {:ok, interval} -> to_dhms(interval)
      :error -> {:error, "Failed to cast to interval"}
    end
  end

  @doc ~S"""
  Bangin' version of `to_dhms/1` (raises on error).
  """
  def to_dhms!(value) do
    case to_dhms(value) do
      {:ok, dhms} -> dhms
      {:error, message} -> raise RuntimeError, message: message
    end
  end

  @spec to_milliseconds(nil | Postgrex.Interval.t()) ::
          {:error, binary} | {:ok, integer}
  def to_milliseconds(nil),
    do: {:error, "Can not convert `nil` interval to milliseconds"}

  def to_milliseconds(%Postgrex.Interval{
        months: 0,
        days: days,
        secs: secs,
        microsecs: 0
      }) do
    {:ok, (days * @secs_per_day + secs) * @millisecs_per_sec}
  end

  def to_milliseconds(%Postgrex.Interval{} = _),
    do:
      {:error,
       "Can not convert to milliseconds -- months and microsecs must both be 0"}

  # `Ecto.Changeset` Validation Helpers
  # --------------------------------------------------------------------------

  def validate_min(changeset, field, %Postgrex.Interval{} = min) do
    changeset
    |> Ecto.Changeset.validate_change(field, fn field, value ->
      case Postgrex.Interval.compare(value, min) do
        :lt -> [{field, "Minimum #{min}"}]
        _ -> []
      end
    end)
  end

  def validate_max(changeset, field, %Postgrex.Interval{} = max) do
    changeset
    |> Ecto.Changeset.validate_change(field, fn field, value ->
      case Postgrex.Interval.compare(value, max) do
        :gt -> [{field, "Maximum #{max}"}]
        _ -> []
      end
    end)
  end

  # `Ecto.Type` Behavior
  # ==========================================================================
  #
  # See https://hexdocs.pm/ecto/Ecto.Type.html
  #

  @impl true
  def type, do: Postgrex.Interval

  # Casting: External → Runtime Representation
  # ----------------------------------------------------------------------------

  @impl true
  def cast(%Postgrex.Interval{} = interval), do: {:ok, interval |> simplify()}

  def cast(%{"mins" => mins} = attrs) do
    attrs
    |> Map.delete("mins")
    |> Map.put(
      "secs",
      to_integer(mins) * 60 +
        (attrs |> Map.get("secs", 0) |> to_integer())
    )
    |> cast()
  end

  def cast(%{"hours" => hours} = attrs) do
    attrs
    |> Map.delete("hours")
    |> Map.put(
      "secs",
      to_integer(hours) * 60 * 60 +
        (attrs |> Map.get("secs", 0) |> to_integer())
    )
    |> cast()
  end

  def cast(%{months: months, days: days, secs: secs}) do
    do_cast(months, days, secs)
  end

  def cast(attrs) when is_map(attrs) do
    do_cast(
      attrs |> Map.get("months", 0),
      attrs |> Map.get("days", 0),
      attrs |> Map.get("secs", 0)
    )
  end

  def cast(value) do
    Logger.error("Interval cast failed", value: value)
    :error
  end

  def cast!(value) do
    case cast(value) do
      {:ok, interval} ->
        interval

      :error ->
        raise ArgumentError,
          message: "Failed to cast to Postgrex.Interval: #{inspect(value)}"
    end
  end

  defp do_cast(months, days, secs) do
    try do
      months = to_integer(months)
      raw_secs = to_integer(secs)
      days = to_integer(days) + div(raw_secs, @secs_per_day)
      secs = rem(raw_secs, @secs_per_day)

      if months == 0 && days == 0 && secs == 0 do
        {:ok, nil}
      else
        {:ok, %Postgrex.Interval{months: months, days: days, secs: secs}}
      end
    rescue
      _ -> :error
    end
  end

  # Loading: Database → Runtime Representation
  # ----------------------------------------------------------------------------

  @impl true
  def load(%{
        months: months,
        days: days,
        secs: secs,
        microsecs: microsecs
      }) do
    # Weirdly, this seems to receive a plain map (presumably) from the Postgrex
    # driver... where I would have expected a `Postgrex.Interval` struct to
    # mirror the
    {:ok,
     %Postgrex.Interval{
       months: months,
       days: days,
       secs: secs,
       microsecs: microsecs
     }}
  end

  # Dumping: Runtime → Database Representation
  # ----------------------------------------------------------------------------

  @impl true
  def dump(%Postgrex.Interval{} = interval) do
    Logger.debug("*** DUMPING ***", interval: interval)
    {:ok, interval}
  end

  def dump(_), do: :error
end

defimpl String.Chars, for: [Postgrex.Interval] do
  import Kernel, except: [to_string: 1]

  @millisecs_per_sec 1_000
  @millisecs_per_microsec 1_000

  def to_string(%Postgrex.Interval{
        months: 0,
        days: 0,
        secs: 0,
        microsecs: 0
      }),
      do: "<None>"

  def to_string(%Postgrex.Interval{
        months: months,
        days: days,
        secs: secs,
        microsecs: microsecs
      }) do
    secs = secs + div(microsecs, @millisecs_per_microsec) / @millisecs_per_sec
    [{"m", months}, {"d", days}, {"s", secs}]
    |> Enum.reduce("", fn {symbol, value}, string ->
      cond do
        value === 0 -> string
        string == "" -> "#{value}#{symbol}"
        true -> "#{string} #{value}#{symbol}"
      end
    end)
  end
end

defimpl Inspect, for: [Postgrex.Interval] do
  def inspect(inv, _opts) do
    inspect(Map.from_struct(inv))
  end
end

if Code.ensure_loaded?(Phoenix.HTML.Safe) do
  defimpl Phoenix.HTML.Safe, for: [Postgrex.Interval] do
    def to_iodata(inv) do
      to_string(inv)
    end
  end
end

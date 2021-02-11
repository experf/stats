defmodule CortexWeb.FormatHelpers do
  use Phoenix.HTML
  require Logger

  def null_tag(), do: content_tag(:span, "null", class: "is-null")

  def maybe(value) when is_nil(value), do: null_tag()

  def maybe(value), do: value

  def fmt(x) when is_nil(x), do: null_tag()

  def fmt(x) when is_binary(x) do
    cond do
      String.match?(x, ~r/https?:\/\//) -> link(x, to: x, target: "_blank")
      true -> x
    end
  end

  def fmt(x) when is_boolean(x) or is_float(x) or is_integer(x) do
    content_tag(:code, x)
  end
end

defmodule CortexWeb.OpenGraphHelpers do
  use Phoenix.HTML
  import Cortex.Types.JSONSchemaMap

  # alias Cortex.OpenGraph

  def open_graph_meta_tag(property, content) do
    tag(:meta, property: property, content: content)
  end

  def reduce({_key, value}, acc) when is_empty(value),
    do: acc

  def reduce({key, value}, acc) when is_list(value),
    do:
      Enum.reduce(value, acc, fn entry, acc ->
        reduce({key, entry}, acc)
      end)

  def reduce({key, value}, acc) when is_map(value),
    do:
      Enum.reduce(value, acc, fn {k, v}, acc ->
        reduce({"#{key}:#{k}", v}, acc)
      end)

  def reduce({key, value}, acc),
    do: [open_graph_meta_tag(key, value) | acc]

  def open_graph_meta_tags(x) when is_nil(x), do: []

  def open_graph_meta_tags(metadata) when is_map(metadata) do
    metadata |> Enum.reduce([], &reduce/2)
  end

  def open_graph_meta_tags_dump(metadata) when is_nil(metadata) do
    content_tag(:span, "null", class: "is-nil")
  end

  def open_graph_meta_tags_dump(metadata) when is_map(metadata) do
    metadata
    |> open_graph_meta_tags()
    |> Enum.map(&safe_to_string/1)
    |> Enum.join("\n")
    |> (fn dump -> content_tag(:pre, dump) end).()
  end
end

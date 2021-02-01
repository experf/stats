defmodule CortexWeb.OpenGraphHelpers do
  use Phoenix.HTML

  alias Cortex.OpenGraph

  def open_graph_meta_tag(property, content) do
    tag(:meta, property: property, content: content)
  end

  defp reduce_sub_struct(_, value, acc) when is_nil(value), do: acc

  defp reduce_sub_struct(key, value, acc) when is_list(value) do
    Enum.reduce(
      value,
      acc,
      fn entry, acc -> reduce_sub_struct(key, entry, acc) end
    )
  end

  defp reduce_sub_struct(key, value, acc)
       when is_atom(key) and is_map(value) do
    [
      open_graph_meta_tag(Atom.to_string(key), value |> Map.get(:url))
      | value
        |> Map.from_struct()
        |> Enum.reduce(acc, fn {k, v}, acc ->
          case {k, v} do
            {_, v} when is_nil(v) -> acc
            {:url, _} -> acc
            {k, v} when is_atom(k) -> [open_graph_meta_tag("#{key}:#{k}", v) | acc]
          end
        end)
    ]
  end

  # EtcHelpers.maybe(x)
  def open_graph_meta_tags(x) when is_nil(x), do: []

  def open_graph_meta_tags(%OpenGraph.Metadata{} = metadata) do
    metadata
    |> Map.from_struct()
    |> Enum.reduce([], fn {key, value}, acc ->
      case {key, value} do
        {_, nil} ->
          acc

        {key, value} when key in [:"og:image", :"og:audio", :"og:video"] ->
          reduce_sub_struct(key, value, acc)

        {key, value} ->
          [open_graph_meta_tag(Atom.to_string(key), to_string(value)) | acc]
      end
    end)
  end

  def open_graph_meta_tags_dump(metadata) when is_nil(metadata) do
    content_tag :span, "null", class: "is-nil"
  end

  def open_graph_meta_tags_dump(%OpenGraph.Metadata{} = metadata) do
    metadata
    |> open_graph_meta_tags()
    |> Enum.map(&safe_to_string/1)
    |> Enum.join("\n")
    |> (fn dump -> content_tag(:pre, dump) end).()
  end
end

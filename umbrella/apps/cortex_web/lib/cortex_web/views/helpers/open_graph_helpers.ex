defmodule CortexWeb.OpenGraphHelpers do
  require Logger
  use Phoenix.HTML
  import Cortex.Types.JSONSchemaMap

  alias CortexWeb.FormatHelpers

  def open_graph_meta_tags_dump(metadata) when is_nil(metadata) do
    FormatHelpers.null_tag()
  end

  def open_graph_meta_tags_dump(metadata) when is_map(metadata) do
    list = metadata |> open_graph_metadata_to_list()
    content_tag(:pre, list |> inspect(pretty: true))
  end

  def flatten([head | tail]), do: flatten(head) ++ flatten(tail)
  def flatten([]), do: []
  def flatten(element), do: [element]

  def open_graph_metadata_to_list({_key, value}) when is_empty(value),
    do: []

  def open_graph_metadata_to_list({key, value}) when is_list(value),
    do:
      Enum.map(value, fn entry ->
        open_graph_metadata_to_list({key, entry})
      end)

  def open_graph_metadata_to_list({key, value}) when is_map(value),
    do:
      value
      |> Enum.map(fn {k, v} ->
        case k do
          "url" -> {key, v}
          _ -> {"#{key}:#{k}", v}
        end
      end)
      |> Enum.sort()
      |> Enum.map(fn {k, v} -> open_graph_metadata_to_list({k, v}) end)

  def open_graph_metadata_to_list(%{open_graph_metadata: metadata}),
    do: open_graph_metadata_to_list(metadata)

  def open_graph_metadata_to_list(metadata) when is_map(metadata) do
    metadata
    |> Map.to_list()
    |> Enum.sort()
    |> Enum.map(&open_graph_metadata_to_list/1)
    |> flatten()
  end

  def open_graph_metadata_to_list(kv),
    do: kv
end

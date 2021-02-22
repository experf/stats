defmodule Birdstrap.HTML.Grid do
  require Logger
  use Phoenix.HTML
  import Birdstrap.HTML.Class

  def row(do: block), do: row(block, [])
  def row(content), do: row(content, [])
  def row(attrs, do: block) when is_list(attrs), do: row(block, attrs)
  def row(content, attrs) when is_list(attrs) do
    content_tag :div, content, attrs |> add_class("row")
  end

  def col(do: block), do: col(block, [])
  def col(content), do: col(content, [])
  def col(attrs, do: block) when is_list(attrs), do: col(block, attrs)
  def col(content, attrs) when is_list(attrs) do
    content_tag :div, content, attrs |> add_class("col")
  end
end

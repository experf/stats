defmodule Birdstrap.HTML.Class do
  require Logger
  use Phoenix.HTML

  def has_class?(none, _) when is_nil(none), do: false

  def has_class?(class_attr, class_name)
      when is_binary(class_attr) and is_binary(class_name) do
    class_attr |> String.split() |> Enum.member?(class_name)
  end

  def has_class?(opts, class_name)
      when is_list(opts) and is_binary(class_name) do
    opts |> Keyword.get(:class) |> has_class?(class_name)
  end

  def add_class(class_attr, class_name)
      when is_binary(class_attr) and is_binary(class_name) do
    if class_attr |> has_class?(class_name) do
      class_attr
    else
      class_name <> " " <> class_attr
    end
  end

  def add_class(opts, class_name)
      when is_list(opts) and is_binary(class_name) do
    Keyword.update(opts, :class, class_name, fn class_attr ->
      class_attr |> add_class(class_name)
    end)
  end
end

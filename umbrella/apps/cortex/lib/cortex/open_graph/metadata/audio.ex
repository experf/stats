defmodule Cortex.OpenGraph.Metadata.Audio do
  alias Cortex.JSONSchema

  defstruct [
    :url,
    :type,
    :secure_url,
  ]

  defp cast_reduce({_, value}, kwds) when is_nil(value) do
    kwds
  end

  defp cast_reduce({ext_key, ext_value}, kwds) do
     [{String.to_existing_atom(ext_key), ext_value} | kwds]
  end

  def cast!(url) when is_binary(url), do: %__MODULE__{url: url}

  def cast!(attrs) when is_map(attrs),
    do: struct!(__MODULE__, attrs |> Enum.reduce([], &cast_reduce/2))

  defp load_reduce({db_key, db_value}, kwds) when is_binary(db_key) do
    [{String.to_existing_atom(db_key), db_value} | kwds]
  end

  def load!(repo_attrs) when is_map(repo_attrs) do
    struct!(__MODULE__, repo_attrs |> Enum.reduce([], &load_reduce/2))
  end

  def dump!(%__MODULE__{} = struct) do
    struct
    |> Map.from_struct()
    |> Enum.reject(&JSONSchema.empty_pair?/1)
    |> Enum.into(%{})
  end
end

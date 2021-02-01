defmodule Cortex.OpenGraph.Metadata.Video do
  defstruct [
    :url,
    :type,
    :secure_url,
    :width,
    :height,
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

  defimpl Jason.Encoder do
    def encode(struct, opts) do
      case struct
           |> Map.from_struct()
           |> Enum.reject(&Cortex.JSONSchema.empty_pair?/1) do
        [] ->
          Jason.encode(nil, opts)

        list ->
          list
          |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
          |> Enum.into(%{})
          |> Jason.Encode.map(opts)
      end
    end
  end
end

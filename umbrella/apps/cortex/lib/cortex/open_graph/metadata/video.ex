defmodule Cortex.OpenGraph.Metadata.Video do
  defstruct [
    :url,
    :type,
    :secure_url,
    :width,
    :height,
  ]

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

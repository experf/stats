defmodule Cortex.OpenGraph.Metadata.Audio do
  defstruct [
    :url,
    :type,
    :secure_url,
  ]

  defimpl Jason.Encoder do
    def encode(struct, opts) do
      case struct
           |> Map.from_struct()
           |> Enum.reject(&Cortex.OpenGraph.Metadata.empty_pair?/1) do
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

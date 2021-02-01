defmodule Cortex.OpenGraph.Metadata.Audio do
  defstruct [
    :url,
    :type,
    :secure_url
  ]

  use Cortex.JSONSchema

  def cast!(url) when is_binary(url), do: %__MODULE__{url: url}
end

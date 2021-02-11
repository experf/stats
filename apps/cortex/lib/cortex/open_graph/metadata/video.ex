defmodule Cortex.OpenGraph.Metadata.Video do
  defstruct [
    :url,
    :type,
    :secure_url,
    :width,
    :height
  ]

  use Cortex.JSONSchema

  def cast!(url) when is_binary(url), do: %__MODULE__{url: url}
end

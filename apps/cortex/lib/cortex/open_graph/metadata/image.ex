defmodule Cortex.OpenGraph.Metadata.Image do
  defstruct [
    :url,
    :type,
    :secure_url,
    :width,
    :height,
    :alt,
  ]

  use Cortex.JSONSchema

  def cast!(url) when is_binary(url), do: %__MODULE__{url: url}

end

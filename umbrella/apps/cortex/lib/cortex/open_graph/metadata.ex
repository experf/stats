defmodule Cortex.OpenGraph.Metadata do
  require Logger

  # https://hexdocs.pm/ecto/Ecto.Type.html
  use Ecto.Type

  alias Cortex.OpenGraph.Metadata.{Image, Audio, Video}

  @schema Application.get_env(:cortex, __MODULE__)[:schema_json]
          |> Jason.decode!(strings: :copy)
          |> JsonXema.new()

  @sub_structs %{
    :"og:image" => Image,
    :"og:audio" => Audio,
    :"og:video" => Video
  }

  defstruct [
    :"og:title",
    :"og:type",
    :"og:url",
    :"og:description",
    :"og:determiner",
    :"og:locale",
    :"og:site_name",
    :"og:image",
    :"og:audio",
    :"og:video"
  ]

  use Cortex.JSONSchema

  # Functions
  # ============================================================================

  def type, do: :map

end

defmodule Cortex.OpenGraph.Metadata do
  use Ecto.Schema
  import Ecto.Changeset
  require Logger

  alias Cortex.OpenGraph.Metadata.Image
  alias Cortex.OpenGraph.Metadata.Audio
  alias Cortex.OpenGraph.Metadata.Video

  # https://hexdocs.pm/ecto/Ecto.Schema.html#embeds_one/3

  embedded_schema do
    field :"og:title", :string
    field :"og:type", :string
    field :"og:url", :string
    field :"og:description", :string
    field :"og:determiner", :string, default: ""
    field :"og:locale", :string, default: "en_US"
    field :"og:site_name", :string

    embeds_many :"og:image", Image
    embeds_many :"og:audio", Audio
    embeds_many :"og:video", Video
  end

  def changeset(schema, params) do
    Logger.debug("### Metadata START ###")
    Logger.debug("###")
    Logger.debug("schema: #{inspect(schema)}")
    Logger.debug("###")
    Logger.debug("params: #{inspect(params)}")
    Logger.debug("### END ###")

    schema
    |> cast(
      params,
      [
        :"og:title",
        :"og:type",
        :"og:url",
        :"og:description",
        :"og:determiner",
        :"og:locale",
        :"og:site_name"
      ]
    )
    |> cast_embed(:"og:image")
    |> cast_embed(:"og:audio")
    |> cast_embed(:"og:video")
  end
end

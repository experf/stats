defmodule Cortex.OpenGraph.Metadata.Video do
  use Ecto.Schema
  import Ecto.Changeset
  require Logger

  # https://hexdocs.pm/ecto/Ecto.Schema.html#embeds_one/3

  embedded_schema do
    field :url, :string
    field :type, :string
    field :secure_url, :string
    field :width, :integer
    field :height, :integer
  end

  def changeset(schema, params) do
    Logger.debug("### Video START ###")
    Logger.debug("###")
    Logger.debug("schema: #{inspect(schema)}")
    Logger.debug("###")
    Logger.debug("params: #{inspect(params)}")
    Logger.debug("### END ###")

    schema
    |> cast(params, [:url, :type, :secure_url, :width, :height])
  end
end

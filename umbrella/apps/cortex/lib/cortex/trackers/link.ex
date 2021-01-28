defmodule Cortex.Trackers.Link do
  use Ecto.Schema
  import Ecto.Changeset
  require Logger

  alias Cortex.Accounts
  alias Cortex.OpenGraph

  @link_gen_id_bytes 4

  @primary_key {:id, :string, autogenerate: false}

  schema "links" do
    field :name, :string
    field :destination_url, :string
    field :redirect_method, :string, default: "http_302"
    field :notes, :string

    belongs_to :inserted_by, Accounts.User
    belongs_to :updated_by, Accounts.User

    embeds_one :open_graph_metadata, OpenGraph.Metadata, on_replace: :update

    timestamps()
  end

  @doc false
  def changeset(link, user, attrs) do
    link
    |> cast(attrs, [:name, :destination_url, :redirect_method, :notes])
    |> cast_embed(:open_graph_metadata)
    |> validate_required([:destination_url, :redirect_method])
    |> put_change(:updated_by_id, user.id)
  end

  def gen_id() do
    :crypto.strong_rand_bytes(@link_gen_id_bytes)
    |> Base.encode16
    |> String.downcase
  end

  @doc false
  def create_changeset(link, %Accounts.User{} = user, attrs) do
    link
    |> cast(attrs, [:id, :name, :destination_url, :redirect_method, :notes])
    |> cast_embed(:open_graph_metadata)
    |> validate_required([:destination_url, :redirect_method])
    |> put_change(:inserted_by_id, user.id)
    |> put_change(:updated_by_id, user.id)
  end
end

defmodule Cortex.Trackers.Link do
  use Ecto.Schema
  import Ecto.Changeset
  require Logger

  alias Cortex.Accounts.User

  @link_gen_id_bytes 4

  @primary_key {:id, :string, autogenerate: false}

  schema "links" do
    field :name, :string
    field :destination_url, :string
    field :redirect_method, :string
    field :notes, :string
    belongs_to :inserted_by, Cortex.Accounts.User
    belongs_to :updated_by, Cortex.Accounts.User
    timestamps()
  end

  @doc false
  def changeset(link, attrs) do
    link
    |> cast(attrs, [])
    |> validate_required([])
  end

  def gen_id(changeset) do
    case fetch_change(changeset, :id) do
      {:ok, _} ->
        changeset

      :error ->
        changeset
        |> put_change(
          :id,
          :crypto.strong_rand_bytes(@link_gen_id_bytes)
          |> Base.encode16
          |> String.downcase
        )
    end
  end

  @doc false
  def create_changeset(link, %User{} = user, attrs) do
    link
    |> cast(attrs, [:id, :name, :destination_url, :redirect_method, :notes])
    |> gen_id()
    |> validate_required([:id, :destination_url, :redirect_method])
    |> put_change(:inserted_by_id, user.id)
    |> put_change(:updated_by_id, user.id)
  end
end

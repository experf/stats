defmodule Cortex.Repo.Migrations.AddOgMetaToLinksTable do
  use Ecto.Migration

  def change do
    alter table(:links) do
      add :open_graph_metadata, :map
    end
  end
end

defmodule Cortex.Repo.Migrations.CreateLinks do
  use Ecto.Migration

  def change do
    create table(:links, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string
      add :destination_url, :string, null: false
      add :redirect_method, :string, null: false
      add :notes, :string
      add :inserted_by_id, references(:users), null: false
      add :updated_by_id, references(:users), null: false
      timestamps()
    end

    create index(:links, [:inserted_by_id])
    create index(:links, [:updated_by_id])
    create index(:links, [:inserted_at])
    create index(:links, [:updated_at])
  end
end

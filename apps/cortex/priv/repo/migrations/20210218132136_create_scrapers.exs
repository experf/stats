defmodule Cortex.Repo.Migrations.CreateScrapers do
  use Ecto.Migration

  def change do
    create table(:scrapers) do
      # Optional name to identify the scraper
      add :name, :string

      # Optional notes
      add :notes, :string

      # The name of the Elixir module to run
      add :module, :string, null: false

      # How often the scraper should run
      add :frequency, :interval

      # After how long (if ever) to kill a run
      add :timeout, :interval

      # State flag to prevent multiple instances running
      add :is_running, :boolean, null: false, default: false

      # When the last run was started (if any)
      add :last_run_started_at, :naive_datetime

      # How long the last run took to complete (if it did)
      add :last_run_duration, :interval

      # What happen as the result of the last run
      add :last_run_status, :string

      # Module-specific configuration data
      add :config, :map

      # Module-specific state data
      add :state, :map

      # Who created the scraper
      add :inserted_by_id, references(:users), null: false

      # Who last edited the scraper
      add :updated_by_id, references(:users), null: false

      timestamps()
    end
  end
end

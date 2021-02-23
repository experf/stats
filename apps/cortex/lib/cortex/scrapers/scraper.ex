defmodule Cortex.Scrapers.Scraper do
  require Logger
  use Ecto.Schema
  import Ecto.Changeset

  alias Cortex.Accounts.User
  alias Cortex.Types.Interval

  @module_values [Cortex.Scrapers.Substack]

  schema "scrapers" do
    # Optional name to identify the scraper
    field :name, :string

    # Optional notes
    field :notes, :string

    # The name of the Elixir module to run
    field :module, Ecto.Enum, values: @module_values

    # How often the scraper should run
    field :frequency, Interval

    # After how long (if ever) to kill a run
    field :timeout, Interval

    # State flag to prevent multiple instances running
    field :is_running, :boolean, default: false

    # When the last run was started (if any)
    field :last_run_started_at, :naive_datetime

    # How long the last run took to complete (if it did)
    field :last_run_duration, Interval

    # What happen as the result of the last run
    field :last_run_status, Ecto.Enum, values: [:ok, :error]

    # Module-specific configuration data
    field :config, :map

    # Module-specific state data
    field :state, :map

    # Who created the scraper
    belongs_to :inserted_by, User

    # Who last edited the scraper
    belongs_to :updated_by, User

    timestamps()
  end

  def module_values(), do: @module_values

  defp validate_frequency(%Ecto.Changeset{} = changeset) do
    changeset
    |> Interval.validate_min(:frequency, %Postgrex.Interval{secs: 30})
    |> Interval.validate_max(:frequency, %Postgrex.Interval{days: 7})
  end

  def changeset(scraper, %User{} = user, attrs) do
    scraper
    |> cast(
      attrs,
      [
        :name,
        :notes,
        :module,
        :frequency,
        :timeout,
        :config
      ]
    )
    |> validate_required([:module])
    |> validate_frequency()
    |> put_change(:updated_by_id, user.id)
  end

  def create_changeset(scraper, %User{} = user, attrs) do
    scraper
    |> cast(
      attrs,
      [
        :name,
        :notes,
        :module,
        :frequency,
        :timeout,
        :config
      ]
    )
    |> validate_required([:module])
    |> validate_frequency()
    |> put_change(:inserted_by_id, user.id)
    |> put_change(:updated_by_id, user.id)
  end
end

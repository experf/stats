defmodule Cortex.Scrapers.Scraper do
  @moduledoc ~S"""
  Scrape Scrape!
  """

  require Logger
  use Ecto.Schema
  use GenServer
  import Ecto.Changeset

  alias Cortex.Repo
  alias Cortex.Accounts.User
  alias Cortex.Types.Interval
  alias Cortex.Types.JSONMap

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
    field :config, JSONMap

    # Module-specific state data
    field :state, JSONMap

    # Who created the scraper
    belongs_to :inserted_by, User

    # Who last edited the scraper
    belongs_to :updated_by, User

    timestamps()
  end

  # Helper Functions
  # ==========================================================================

  @doc ~S"""
  String format a `module` field value. Shortens it where redundant, removing
  leading `"Elixir."` to match the programing language and additional leading
  `"Cortex.Scrapers."` so we're not printing that in front of all (or most all)
  of them.

  ## Examples

  1.  A `Cortex.Scrapers` sub-module:

          iex> Cortex.Scrapers.Substack
          ...> |> Cortex.Scrapers.Scraper.module_name()
          "Substack"

  2.  Same thing using the full `atom` version:

          iex> :"Elixir.Cortex.Scrapers.Substack"
          ...> |> Cortex.Scrapers.Scraper.module_name()
          "Substack"

  3.  Strings work too:

          iex> "Elixir.Cortex.Scrapers.Substack"
          ...> |> Cortex.Scrapers.Scraper.module_name()
          "Substack"

  4.  Everything else just passes through:

          iex> :blah |> Cortex.Scrapers.Scraper.module_name()
          "blah"

          iex> "Elixir.Some.Other.Mod" |> Cortex.Scrapers.Scraper.module_name()
          "Some.Other.Mod"

  """
  @spec module_name(atom | binary) :: binary
  def module_name(module) when is_binary(module) do
    module
    |> String.replace(~r/^Elixir\./, "")
    |> String.replace(~r/^Cortex\.Scrapers\./, "")
  end

  def module_name(module) when is_atom(module),
    do: module |> Atom.to_string() |> module_name()

  @doc ~S"""
  What to call a `Cortex.Scrapers.Scraper` struct.

  ## Examples

  1.  When it has a `name`, it's just that `name`:

          iex> %Cortex.Scrapers.Scraper{name: "Scrape scrape!"}
          ...> |> Cortex.Scrapers.Scraper.name()
          "Scrape scrape!"

  2.  Otherwise, it sucks, but it's something:

          iex> %Cortex.Scrapers.Scraper{id: 123}
          ...> |> Cortex.Scrapers.Scraper.name()
          "Scraper#123"
  """
  @spec name(%Cortex.Scrapers.Scraper{}) :: binary
  def name(%__MODULE__{name: name}) when is_binary(name), do: name
  def name(%__MODULE__{name: nil, id: id}), do: "Scraper##{id}"

  def summary(%__MODULE__{module: module, frequency: frequency} = scraper) do
    "#{name(scraper)} (#{module_name(module)} every #{frequency}})"
  end

  # Schema Functions
  # ==========================================================================

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

  defp run_changeset(scraper, attrs) do
    scraper
    |> cast(attrs, [:last_run_started_at, :last_run_duration, :state])
    # |> validate_
  end

  # GenServer Functions
  # ==========================================================================
  #
  # 1.  https://hexdocs.pm/elixir/GenServer.html#module-receiving-regular-messages
  #

  def gen_server_name(%__MODULE__{id: id}) when is_integer(id) do
    {:global, {__MODULE__, id}}
  end

  def start_link(%__MODULE__{} = scraper) do
    GenServer.start_link(__MODULE__, scraper, name: gen_server_name(scraper))
  end

  def stop(%__MODULE__{} = scraper) do
    scraper
    |> gen_server_name()
    |> GenServer.stop()
  end

  @impl true
  def init(%__MODULE__{id: id} = _scraper) do
    # schedule_work(scraper)
    Process.send_after(self(), :work, 1_000)
    {:ok, id}
  end

  @impl true
  def handle_info(:work, id) do
    Logger.info("Doing work!", scraper_id: id)

    scraper = Repo.get!(__MODULE__, id)

    duration_start = System.monotonic_time(:microsecond)
    started_at = NaiveDateTime.utc_now()

    case apply(scraper.module, :scrape, [scraper]) do
      {:ok, new_state} ->
        duration_end = System.monotonic_time(:microsecond)
        duration =
            %Postgrex.Interval{microsecs: duration_end - duration_start}
            |> Interval.simplify()

        Logger.info(
          "#{scraper} scrape done, updating database record...",
          duration: to_string(duration)
        )

        scraper
        |> run_changeset(%{
          state: new_state,
          last_run_started_at: started_at,
          last_run_duration: duration
        })
        |> Repo.update()
    end

    # Reschedule once more
    schedule_work(scraper)

    {:noreply, id}
  end

  def schedule_work(%__MODULE__{} = scraper) do
    case scraper.frequency |> Interval.to_milliseconds() do
      {:ok, ms} ->
        Logger.info("Scheduling scraper #{scraper}",
          in_milliseconds: ms,
          scraper_id: scraper.id
        )

        Process.send_after(self(), :work, ms)

      {:error, error} ->
        Logger.error(
          "Unable to schedule scraper #{scraper}",
          scraper_id: scraper.id,
          error: error
        )
    end
  end

  # Protocol Implementations
  # ==========================================================================

  defimpl String.Chars do
    def to_string(%@for{} = scraper) do
      scraper |> @for.name()
    end
  end
end

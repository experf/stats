defmodule Cortex.Scrapers.Substack do
  require Logger

  alias Cortex.Scrapers.Scraper
  alias Cortex.Ext
  alias Cortex.Scrapers.Substack.Subscriber

  @type t :: %__MODULE__{
    app: binary,
    client: Subscrape.t(),
    last_subscriber_event_at: nil | DateTime.t(),
    last_subscriber_email: nil | binary,
  }

  defstruct [
    :app,
    :client,
    :last_subscriber_event_at,
    :last_subscriber_email
  ]

  def new(config, nil), do: new(config, %{})

  def new(%{"app" => app, "client" => client_props}, state)
      when is_binary(app) do
    client =
      client_props
      |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
      |> Subscrape.new()

    last_subscriber_event_at =
      state
      |> Map.get("last_subscriber_event_at")
      |> case do
        nil -> nil
        s when is_binary(s) -> s |> Ext.DateTime.from_iso8601!()
      end

    last_subscriber_email = state |> Map.get("last_subscriber_email")

    __MODULE__
    |> struct!(
      app: app,
      client: client,
      last_subscriber_event_at: last_subscriber_event_at,
      last_subscriber_email: last_subscriber_email
    )
  end

  def to_state(%__MODULE__{} = this) do
    %{
      "last_subscriber_email" => this.last_subscriber_email,
      "last_subscriber_event_at" => this.last_subscriber_event_at
    }
  end

  def scrape(%Scraper{id: id, config: config, state: state}) do
    this = new(config, state)

    Logger.info("Scraping Substack", scraper_id: id, this: this)

    this = this |> Subscriber.Event.scrape!()

    {:ok, this |> to_state()}
  end

  # def scrape(%Subscrape{} = config, app) do
  #   scrape_id = Ecto.UUID.generate()
  #   start_ms = System.monotonic_time(:millisecond)

  #   Events.produce(%{
  #     app: "cortex",
  #     type: "scrape.start",
  #     name: "substack",
  #     id: scrape_id,
  #     substack: %{
  #       app: app,
  #       subdomain: config.subdomain
  #     }
  #   })

  #   case Clients.Substack.subscriber_list(client) do
  #     {:ok, subscriber_list} ->
  #       divisor = 32
  #       chunk_size = ceil(Enum.count(subscriber_list) / divisor)
  #       timeout_ms = chunk_size * 20 * 1000

  #       subscriber_list
  #       |> Enum.chunk_every(chunk_size)
  #       |> Enum.map(fn chunk ->
  #         Task.async(fn -> scrape_subscriber_events(client, app, chunk) end)
  #       end)
  #       |> Enum.map(fn task -> Task.await(task, timeout_ms) end)

  #       delta_ms = System.monotonic_time(:millisecond) - start_ms

  #       Events.produce(%{
  #         app: "cortex",
  #         type: "scrape.done",
  #         name: "substack",
  #         id: scrape_id,
  #         count: Enum.count(subscriber_list),
  #         delta_ms: delta_ms,
  #         substack: %{
  #           app: app,
  #           subdomain: client.subdomain
  #         }
  #       })

  #     {:error, error} ->
  #       delta_ms = System.monotonic_time(:millisecond) - start_ms

  #       Events.produce(%{
  #         app: "cortex",
  #         type: "scrape.fail",
  #         name: "substack",
  #         id: scrape_id,
  #         delta_ms: delta_ms,
  #         substack: %{
  #           app: app,
  #           subdomain: client.subdomain
  #         },
  #         error: error |> Map.from_struct()
  #       })
  #   end
  # end
end

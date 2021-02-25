defmodule Cortex.Scrapers.Substack do
  require Logger

  alias Cortex.Events
  alias Cortex.Scrapers.Scraper
  alias Cortex.Ext

  @event_subtypes %{
    "Clicked link in email" => "email.link.click",
    "Dropped email" => "sub.drop",
    "Free Signup" => "sub.new",
    "Opened email" => "email.open",
    "Post seen" => "post.view",
    "Received email" => "email.receive"
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

  def to_state(%__MODULE__{} = self) do
    %{
      "last_subscriber_email" => self.last_subscriber_email,
      "last_subscriber_event_at" => self.last_subscriber_event_at
    }
  end

  def prepare_subscriber_event(
        app,
        email,
        %{"text" => text, "timestamp" => iso8601} = event
      ) do
    subtype = @event_subtypes |> Map.get(text, "other")

    {
      iso8601 |> Ext.DateTime.from_iso8601!(),
      %{
        type: "substack.subscriber.event",
        app: app,
        email: email,
        src: event,
        subtype: subtype
      }
    }
  end

  def scrape_new_subscriber_events(_self, []), do: []

  def scrape_new_subscriber_events(
        %__MODULE__{app: app, client: client},
        subscribers
      ) do
    subscribers
    |> Enum.reduce(
      [],
      fn %{"email" => email}, result ->
        events =
          client
          |> Subscrape.Subscriber.Event.all!(email)
          |> Enum.map(fn event ->
            prepare_subscriber_event(app, email, event)
          end)

        result |> Enum.concat(events)
      end
    )
  end

  def scrape_updated_subscriber_events(_self, []), do: []

  def scrape_updated_subscriber_events(
        %__MODULE__{
          app: app,
          client: client,
          last_subscriber_event_at: last_subscriber_event_at
        },
        subscribers
      ) do
    subscribers
    |> Enum.reduce(
      [],
      fn %{"email" => email}, result ->
        events =
          client
          |> Subscrape.Subscriber.Event.since!(
            email,
            last_subscriber_event_at
          )
          |> Enum.map(fn event ->
            prepare_subscriber_event(app, email, event)
          end)

        result |> Enum.concat(events)
      end
    )
  end

  # This is the initial-state case, when there is no state information about
  # what events have been scraped.
  #
  # In this case, we scrape _everyone_. It takes some time.
  #
  defp subscribers_to_scrape(%__MODULE__{
         client: client,
         last_subscriber_event_at: nil
       }),
       do: {client |> Subscrape.Subscriber.list!(), []}

  defp subscribers_to_scrape(%__MODULE__{
         client: client,
         last_subscriber_event_at: %DateTime{} = last_subscriber_event_at,
         last_subscriber_email: last_subscriber_email
       }) do
    {new_subs, previously_scraped_subs} =
      client
      |> Subscrape.Subscriber.list!()
      |> Enum.split_while(fn %{"email" => email} ->
        email != last_subscriber_email
      end)

    updated_subs =
      previously_scraped_subs
      |> Subscrape.Subscriber.active_since(last_subscriber_event_at)

    {new_subs, updated_subs}
  end

  def produce_subscriber_events!([]) do
    Logger.info("No new subscriber events")
    :ok
  end

  def produce_subscriber_events!(event_values) when is_list(event_values) do
    for chunk <- event_values |> Enum.chunk_every(100),
      do: chunk |> Events.produce!()

    :ok
  end

  defp most_recent_datetime_from_events(event_values) do
    event_values
    |> Enum.max_by(&elem(&1, 0), DateTime)
    |> elem(0)
  end

  defp first_email_from_events([{_datetime, %{email: email}} | _]), do: email

  # If we are recoding _no_ events, then there is no update.
  def update(%__MODULE__{} = self, []), do: self

  def update(%__MODULE__{} = self, event_values) when is_list(event_values) do
    %{
      self
      | last_subscriber_email: first_email_from_events(event_values),
        last_subscriber_event_at: most_recent_datetime_from_events(event_values)
    }
  end

  def scrape(%Scraper{id: id, config: config, state: state}) do
    self = new(config, state)

    Logger.info("Scraping Substack", scraper_id: id, self: self)

    {new_subs, updated_subs} = self |> subscribers_to_scrape()

    new_sub_events = self |> scrape_new_subscriber_events(new_subs)
    updated_sub_events = self |> scrape_updated_subscriber_events(updated_subs)

    all_sub_events = new_sub_events ++ updated_sub_events

    Logger.debug(
      "COUNTS",
      new: new_sub_events |> length(),
      updated: updated_sub_events |> length(),
      all: all_sub_events |> length()
    )

    all_sub_events |> produce_subscriber_events!()

    {:ok, self |> update(all_sub_events) |> to_state()}
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

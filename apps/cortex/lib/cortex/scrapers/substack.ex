defmodule Cortex.Scrapers.Substack do
  require Logger

  alias Cortex.Events
  alias Cortex.Scrapers.Scraper

  @event_subtypes %{
    "Clicked link in email" => "email.link.click",
    "Dropped email" => "sub.drop",
    "Free Signup" => "sub.new",
    "Opened email" => "email.open",
    "Post seen" => "post.view",
    "Received email" => "email.receive",
  }

  def iso8601_to_unix_ms(iso8601) when is_binary(iso8601) do
    # `datetime` will be in UTC, with `_offset_seconds` storing the offset
    # info encoded in the `iso8601` string ("...T+08:00", etc.).
    #
    # Since we are headed for unix time, which _is_ UTC, we don't need to use
    # that data -- we can go strait from the UTC datetime to unix.
    {:ok, datetime, _offset_seconds} = DateTime.from_iso8601(iso8601)
    DateTime.to_unix(datetime, :millisecond)
  end

  def extract_unix_ms(%{"timestamp" => iso8601}) when is_binary(iso8601) do
    iso8601_to_unix_ms(iso8601)
  end

  def prepare_subscriber_event(
    app,
    email,
    %{"text" => text} = event
  ) do
    subtype = @event_subtypes |> Map.get(text, "other")

    {
      %{
        type: "substack.subscriber.event",
        app: app,
        email: email,
        src: event,
        subtype: subtype,
      },
      event |> extract_unix_ms()
    }
  end

  def prepare_subscriber_events(app, email, events)
      when is_binary(app) and is_binary(email) and is_list(events) do
    for event <- events do
      prepare_subscriber_event(app, email, event)
    end
  end

  def scrape_subscriber_events(%Subscrape{} = config, app) do
    {:ok, subscriber_events} = config |> Subscrape.Subscriber.Event.all("blah")
    for {email, events} <- subscriber_events do
      for {props, unix_ms} <- prepare_subscriber_events(app, email, events) do
        Events.produce(props, unix_ms)
      end
    end
  end

  def scrape(%Scraper{id: id, state: state}) do
    delay = Enum.random(1_000..3_000)
    Logger.info("Scraping Substack", scraper_id: id, delay: "#{delay}ms")
    Process.sleep(delay)
    {:ok, %{delay: delay}}
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

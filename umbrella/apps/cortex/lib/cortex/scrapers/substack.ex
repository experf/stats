defmodule Cortex.Scrapers.Substack do
  alias Cortex.Events
  alias Cortex.Clients

  def iso8601_to_unix_ms(iso8601) when is_binary(iso8601) do
    # `datetime` will be in UTC, with `_offset_seconds` storing the offset
    # info encoded in the `iso8601` string ("...T+08:00", etc.).
    #
    # Since we are headed for unix time, which _is_ UTC, we don't need to use
    # that data -- we can go strait from the UTC datetime to unix.
    {:ok, datetime, _offset_seconds} = DateTime.from_iso8601(iso8601)
    DateTime.to_unix(datetime, :millisecond)
  end

  def extract_unix_ms(%{"timestamp" => iso8601} = event, app)
      when is_binary(iso8601) do
    {iso8601_to_unix_ms(iso8601),
     %{
       app: app,
       type: "substack.subscriber.event",
       event: event
     }}
  end

  def scrape_subscriber_events(client, app, %{"email" => email}) do
    scrape_subscriber_events(client, app, email)
  end

  def scrape_subscriber_events(client, app, email) when is_binary(email) do
    {:ok, events} = Clients.Substack.subscriber_events(client, email)

    for event <- events do
      event |> extract_unix_ms(app) |> Events.produce()
    end

    :ok
  end

  def scrape_subscriber_events(client, app, subscribers)
      when is_list(subscribers) do
    for subscriber <- subscribers,
        do: scrape_subscriber_events(client, app, subscriber)
  end

  def scrape(%Clients.Substack{} = client, app) do
    scrape_id = Ecto.UUID.generate()
    start_ms = System.monotonic_time(:millisecond)

    Events.produce(%{
      app: "cortex",
      type: "scrape.start",
      name: "substack",
      id: scrape_id,
      substack: %{
        app: app,
        subdomain: client.subdomain
      }
    })

    case Clients.Substack.subscriber_list(client) do
      {:ok, subscriber_list} ->
        # subscriber_list = subscriber_list |> Enum.take(1)
        divisor = 32
        chunk_size = ceil(Enum.count(subscriber_list) / divisor)
        timeout_ms = chunk_size * 10 * 1000

        subscriber_list
        |> Enum.chunk_every(chunk_size)
        |> Enum.map(fn chunk ->
          Task.async(fn -> scrape_subscriber_events(client, app, chunk) end)
        end)
        |> Enum.map(fn task -> Task.await(task, timeout_ms) end)

        delta_ms = System.monotonic_time(:millisecond) - start_ms

        Events.produce(%{
          app: "cortex",
          type: "scrape.done",
          name: "substack",
          id: scrape_id,
          count: Enum.count(subscriber_list),
          delta_ms: delta_ms,
          substack: %{
            app: app,
            subdomain: client.subdomain
          }
        })

      {:error, error} ->
        delta_ms = System.monotonic_time(:millisecond) - start_ms

        Events.produce(%{
          app: "cortex",
          type: "scrape.fail",
          name: "substack",
          id: scrape_id,
          delta_ms: delta_ms,
          substack: %{
            app: app,
            subdomain: client.subdomain
          },
          error: error |> Map.from_struct()
        })
    end
  end
end

defmodule Cortex.Scrapers.Substack do
  alias Cortex.Events
  alias Cortex.Clients

  def scrape_subscriber_events(client, app, subscriber) when is_map(subscriber) do
    with {:ok, events} <- Clients.Substack.subscriber_events(client, subscriber) do
      for event <- events do
        Events.produce(%{
          app: app,
          type: "substack.subscriber.event",
          event: event,
        })
      end
    end
    :ok
  end

  def scrape_subscriber_events(client, app, subscribers) when is_list(subscribers) do
    for subscriber <- subscribers,
      do: scrape_subscriber_events(client, app, subscriber)
    :ok
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
      },
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
        |> Enum.map(
          fn(task) -> Task.await(task, timeout_ms) end
        )

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
          },
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

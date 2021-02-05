defmodule Cortex.Scrapers.Substack do
  alias Cortex.Events
  alias Cortex.Clients

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
        for subscriber <- subscriber_list do
          Events.produce(%{
            app: app,
            type: "scrape.substack.subscriber",
            subdomain: client.subdomain,
            subscriber: subscriber,
            scrape: %{
              id: scrape_id
            },
          })
        end

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

defmodule Cortex.Scrapers.Substack do
  alias Cortex.Events

  def subscriber_list(subdomain, sid, after_user \\ nil) do
    limit = 100

    url = "https://#{subdomain}.substack.com/api/v1/subscriber/"

    headers = [
      {"authority", "#{subdomain}.substack.com"},
      {"user-agent",
       "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) " <>
         "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.135 " <>
         "Safari/537.36"},
      {"dnt", "1"},
      {"content-type", "application/json"},
      {"accept", "*/*"},
      {"origin", "https://#{subdomain}.substack.com"},
      {"sec-fetch-site", "same-origin"},
      {"sec-fetch-mode", "cors"},
      {"sec-fetch-dest", "empty"},
      {"referer", "https://#{subdomain}.substack.com/publish/subscribers"},
      {"accept-language", "en-US,en;q=0.9"},
      {"cookie", "substack.sid=#{sid}"}
    ]

    # https://hexdocs.pm/httpoison/HTTPoison.Request.html
    args = %{"term" => "", "filter" => nil, "limit" => limit}

    args =
      if is_nil(after_user),
        do: args,
        else: args |> Map.put("after", after_user)

    body = args |> Jason.encode!()

    with {:ok, %HTTPoison.Response{} = response} <-
           HTTPoison.post(url, body, headers),
         {:ok, %{"subscribers" => users}} when is_list(users) <-
           response.body |> Jason.decode() do
      case Enum.count(users) do
        ^limit ->
          case subscriber_list(subdomain, sid, users |> List.last()) do
            {:ok, rest} -> {:ok, users ++ rest}
            {:error, _} = error -> error
          end
        _ -> {:ok, users}
      end
    end
  end

  def subscriber_time_series() do
    # TODO
  end

  def scrape(app, subdomain, sid) do
    scrape_id = Ecto.UUID.generate()
    start_ms = System.monotonic_time(:millisecond)

    Events.produce(%{
      app: "cortex",
      type: "scrape.start",
      name: "substack",
      id: scrape_id,
    })

    case subscriber_list(subdomain, sid) do
      {:ok, subscriber_list} ->
        for subscriber <- subscriber_list do
          Events.produce(%{
            app: app,
            type: "scrape.substack.subscriber",
            subdomain: subdomain,
            subscriber: subscriber,
            scrape: %{
              id: scrape_id,
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
            subdomain: subdomain,
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
            subdomain: subdomain,
          },
          error: error |> Map.from_struct(),
        })
    end
  end
end

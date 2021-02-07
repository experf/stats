defmodule Cortex.Clients.Substack do
  require Logger

  @options [timeout: 25_000, recv_timeout: 25_000]

  @enforce_keys [:subdomain, :sid]
  defstruct [
    :subdomain,
    :sid
  ]

  def authority(%__MODULE__{} = client), do: "#{client.subdomain}.substack.com"

  def url(%__MODULE__{} = client, path \\ nil) do
    %URI{
      scheme: "https",
      authority: client |> authority(),
      path: path
    }
    |> URI.to_string()
  end

  def url(%__MODULE__{} = client, path, query)
      when is_binary(path) and (is_list(query) or is_map(query)) do
    %URI{
      scheme: "https",
      authority: client |> authority(),
      path: path,
      query: query |> URI.encode_query()
    }
    |> URI.to_string()
  end

  def headers(%__MODULE__{} = client, referer) do
    [
      {"authority", client |> authority()},
      {"pragma", "no-cache"},
      {"cache-control", "no-cache"},
      {"user-agent",
       "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) " <>
         "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.135 " <>
         "Safari/537.36"},
      {"dnt", "1"},
      {"content-type", "application/json"},
      {"accept", "*/*"},
      {"origin", client |> url()},
      {"sec-fetch-site", "same-origin"},
      {"sec-fetch-mode", "cors"},
      {"sec-fetch-dest", "empty"},
      {"referer", referer},
      {"accept-language", "en-US,en;q=0.9"},
      {"cookie", "substack.sid=#{client.sid}"}
    ]
  end

  defp collect(
         %__MODULE__{} = client,
         url,
         args,
         headers,
         limit,
         request_key,
         response_key
       ) do
    with {:ok, body} <-
           args |> Jason.encode(),
         {:ok, %HTTPoison.Response{} = response} <-
           HTTPoison.post(url, body, headers, @options),
         {:ok, %{^response_key => records}} when is_list(records) <-
           response.body |> Jason.decode() do
      case Enum.count(records) do
        ^limit ->
          case collect(
                 client,
                 url,
                 args |> Map.put(request_key, records |> List.last()),
                 headers,
                 limit,
                 request_key,
                 response_key
               ) do
            {:ok, rest} -> {:ok, records ++ rest}
            {:error, _} = error -> error
          end

        _ ->
          {:ok, records}
      end
    end
  end

  def subscriber_list(%__MODULE__{} = client) do
    limit = 100

    url = client |> url("/api/v1/subscriber/")

    headers = client |> headers(client |> url("/publish/subscribers"))

    args = %{"term" => "", "filter" => nil, "limit" => limit}

    collect(client, url, args, headers, limit, "after", "subscribers")
  end

  def subscriber_events(%__MODULE__{} = client, email) when is_binary(email) do
    Logger.debug("Getting substack subscriber events", email: email)

    limit = 20

    url = client |> url("/api/v1/subscriber/#{URI.encode(email)}/events")

    headers =
      client |> headers(client |> url("/publish/subscribers", email: email))

    args = %{"email" => email, "limit" => limit}

    collect(client, url, args, headers, limit, "before", "events")
  end

  def subscriber_events(%__MODULE__{} = client, %{"email" => email}),
    do: subscriber_events(client, email)

  # def subscriber_events(%__MODULE__{} = client, subscribers)
  #     when is_list(subscribers) do

  # end

  # def subscriber_events(%__MODULE__{} = client, :all) do
  #   with {:ok, subscriber_list} = subscriber_list(client) do
  #     divisor = 8
  #     chunk_size = ceil(Enum.count(subscriber_list) / divisor)
  #     timeout_ms = chunk_size * 20 * 1000

  #     subscriber_list
  #     |> Enum.chunk_every(chunk_size)
  #     |> Enum.map(fn chunk ->
  #       Task.async(fn -> subscriber_events(client, app, chunk) end)
  #     end)
  #     |> Enum.map(fn task -> Task.await(task, timeout_ms) end)
  #   end
  # end
end

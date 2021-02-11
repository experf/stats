defmodule Subscrape.HTTP do
  @moduledoc """
  Documentation for `Subscrape`.
  """

  require Logger
  require Subscrape.Helpers

  alias Subscrape.Cache
  alias Subscrape.Endpoint

  # SEE https://hexdocs.pm/httpoison/HTTPoison.Request.html
  @httpoison_request_option_keys ~w(
    timeout recv_timeout stream_to async proxy proxy_auth socks5_user
    socks5_pass ssl follow_redirect max_redirect params max_body_length
  )a

  def authority(%Subscrape{} = client), do: "#{client.subdomain}.substack.com"

  def url(%Subscrape{} = client), do: url(client, nil, nil)

  def url(%Subscrape{} = client, path) when is_binary(path),
    do: url(client, path, nil)

  def url(%Subscrape{} = client, %Endpoint{} = endpoint) do
    url(client, EEx.eval_string(endpoint.format, []))
  end

  def url(%Subscrape{} = client, {%Endpoint{} = endpoint, kwds}) do
    encoded_kwds =
      kwds
      |> Enum.map(fn {k, v} ->
        {k, v |> to_string() |> URI.encode_www_form()}
      end)

    path = endpoint.format |> EEx.eval_string(encoded_kwds)

    url(client, path)
  end

  def url(%Subscrape{} = client, {template, kwds}) do
    encoded_kwds =
      kwds
      |> Enum.map(fn {k, v} ->
        {k, v |> to_string() |> URI.encode_www_form()}
      end)

    path = template |> EEx.eval_string(encoded_kwds)

    url(client, path)
  end

  def url(%Subscrape{} = client, path, query)
      when is_binary(path) and (is_list(query) or is_map(query)),
      do: url(client, path, query |> URI.encode_query())

  def url(%Subscrape{} = client, path, query) do
    uri(client, path, query) |> URI.to_string()
  end

  def uri(%Subscrape{} = client, path, query) do
    %URI{
      scheme: "https",
      authority: client |> authority(),
      path: path,
      query: query
    }
  end

  def headers(%Subscrape{} = client) do
    [
      {"authority", client |> authority()},
      {"pragma", "no-cache"},
      {"cache-control", "no-cache"},
      {"user-agent",
       "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) " <>
         "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.135 " <>
         "Safari/537.36"},
      {"content-type", "application/json"},
      {"accept", "*/*"},
      {"origin", client |> url()},
      {"sec-fetch-site", "same-origin"},
      {"sec-fetch-mode", "cors"},
      {"sec-fetch-dest", "empty"},
      {"accept-language", "en-US,en;q=0.9"},
      {"cookie", "substack.sid=#{client.sid}"}
    ]
  end

  def collect(client, endpoint, args, opts \\ [])

  def collect(%Subscrape{} = client, %Endpoint{} = endpoint, args, opts),
    do: collect(client, {endpoint, []}, args, opts)

  def collect(
        %Subscrape{} = client,
        {
          %Endpoint{
            extract_key: extract_key,
            page_key: page_key
          },
          _
        } = endpoint,
        %{"limit" => limit} = args,
        opts
      ) when is_binary(extract_key) and is_binary(page_key) do
    Logger.debug(
      "START collecting...",
      subdomain: client.subdomain,
      endpoint: endpoint,
      args: args,
      opts: opts
    )

    case collect__internal(client, endpoint, args, opts) do
      {:ok, records} = result ->
        Logger.debug(
          "DONE collecting",
          subdomain: client.subdomain,
          endpoint: endpoint,
          limit: limit,
          total_records: Enum.count(records)
        )

        result

      {:error, error} = result ->
        Logger.debug(
          "FAIL collecting",
          subdomain: client.subdomain,
          endpoint: endpoint,
          limit: limit,
          error: error
        )

        result
    end
  end

  defp collect__internal(
         %Subscrape{} = client,
         {
           %Endpoint{
             extract_key: extract_key,
             page_key: page_key
           },
           _
         } = endpoint,
         %{"limit" => limit} = args,
         opts
       ) do
    with {:ok, %{^extract_key => records}} when is_list(records) <-
           client |> request(endpoint, args, opts) do
      case Enum.count(records) do
        ^limit ->
          case collect__internal(
                 client,
                 endpoint,
                 args |> Map.put(page_key, records |> List.last()),
                 opts
               ) do
            {:ok, rest} -> {:ok, records ++ rest}
            {:error, _} = result -> result
          end

        _ ->
          {:ok, records}
      end
    end
  end

  def request(%Subscrape{} = client, endpoint, args, opts \\ []) do
    url = url(client, endpoint)

    Logger.debug(
      "START -- Substack request",
      url: url,
      args: args,
      opts: opts
    )

    case Cache.get(client, url, args) do
      {:hit, b} ->
        Logger.debug(
          "DONE -- Substack request -- CACHE HIT",
          endpoint: endpoint,
          args: args,
          opts: opts
        )

        {:ok, b |> Jason.decode!()}

      :miss ->
        case try_request(client, url, args, opts) do
          {:ok, %HTTPoison.Response{} = r} ->
            Logger.debug(
              "RECEIVED -- Substack request",
              endpoint: endpoint,
              args: args,
              opts: opts
            )

            process_response(client, r)

          {:error, e} = result ->
            Logger.error(
              "HTTP FAIL -- Substack request",
              url: url,
              args: args,
              opts: opts,
              error: e
            )

            result
        end
    end
  end

  defp process_response(
         %Subscrape{} = client,
         %HTTPoison.Response{
           status_code: status,
           request_url: url,
           body: body
         } = response
       ) do
    case body |> Jason.decode() do
      {:ok, payload} = result ->
        Logger.debug(
          "DONE -- Substack request",
          status: status,
          url: url,
          args: response.request.options[:args]
        )

        if status == 200 do
          Cache.put(client, response)
          result
        else
          {:error, [status: status, payload: payload]}
        end

      {:error, decode_error} ->
        Logger.error(
          "JSON FAIL -- decoding HTTP #{status} response from Substack",
          response: response,
          decode_error: decode_error
        )

        {:error, [status: status, response: response]}
    end
  end

  defp try_request(%Subscrape{} = client, url, args, opts)
       when is_binary(url) and (is_nil(args) or is_map(args)) and
              is_list(opts) do
    request_options = opts |> Keyword.take(@httpoison_request_option_keys)
    params = request_options |> Keyword.get(:params, [])
    method = if is_nil(args), do: :get, else: :post

    request = %HTTPoison.Request{
      method: method,
      url: url |> HTTPoison.Base.build_request_url(params),
      headers: client |> headers(),
      body: if(is_nil(args), do: "", else: args |> Jason.encode!(args)),
      params: params,
      # Shove `args` into the `options` so that we have it available for
      # logging if needed without having to pass it around too the whole time
      options: request_options |> Keyword.put(:args, args)
    }

    max_attempts = client |> Subscrape.opt!(opts, :max_retry_attempts)

    try_request(client, request, max_attempts, [])
  end

  defp try_request(%Subscrape{} = client, request, max_attempts, errors)
       when is_integer(max_attempts) and is_list(errors) and
              max_attempts >= 1 and length(errors) >= max_attempts do
    Logger.error(
      "#{max_attempts} Substack request attempts ALL FAILED, giving up",
      subdomain: client.subdomain,
      attempts: max_attempts,
      request: request,
      errors: errors
    )

    {:error, "All retry attempts failed, see error log for details"}
  end

  defp try_request(%Subscrape{} = client, request, max_attempts, errors)
       when is_integer(max_attempts) and is_list(errors) and
              max_attempts >= 1 do
    Logger.debug(
      "SEND -- Substack HTTP request...",
      request: request,
      attempt: length(errors),
      max_attempts: max_attempts
    )

    case request |> HTTPoison.request() do
      {:ok, _} = result ->
        result

      {:error, %HTTPoison.Error{} = error} ->
        errors = [error | errors]

        Logger.warn(
          "Substack request FAILED " <>
            "(attempt #{length(errors)}/#{max_attempts}), retrying...",
          subdomain: client.subdomain,
          attempts: max_attempts,
          request: request,
          error: error
        )

        try_request(client, request, max_attempts, errors)
    end
  end
end

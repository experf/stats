defmodule Subscrape.HTTP do
  @moduledoc """
  Documentation for `Subscrape`.
  """

  require Logger

  alias Subscrape.Cache
  alias Subscrape.Endpoint

  # SEE https://hexdocs.pm/httpoison/HTTPoison.Request.html
  @httpoison_request_option_keys ~w(
    timeout recv_timeout stream_to async proxy proxy_auth socks5_user
    socks5_pass ssl follow_redirect max_redirect params max_body_length
  )a

  @doc ~S"""
  The domain, given the `:subdomain` of the config.
  """
  def authority(%Subscrape{} = config),
    do: "#{config.subdomain}.substack.com"

  def url(%Subscrape{} = config, path \\ nil, query \\ nil),
    do: uri(config, path, query) |> URI.to_string()

  def uri(%Subscrape{} = config, path, query) do
    %URI{
      scheme: "https",
      authority: config |> authority(),
      path: path |> encode_path(),
      query: query |> encode_query()
    }
  end

  defp encode_path(path) do
    case path do
      nil -> nil
      str when is_binary(str) -> str
      %Endpoint{} = ep -> ep |> Endpoint.to_path()
      {%Endpoint{} = ep, kwds} -> ep |> Endpoint.to_path(kwds)
    end
  end

  defp encode_query(query) do
    case query do
      nil -> nil
      str when is_binary(str) -> str
      enum when is_list(enum) or is_map(enum) -> URI.encode_query(enum)
    end
  end

  def headers(%Subscrape{} = config) do
    [
      {"authority", config |> authority()},
      {"pragma", "no-cache"},
      {"cache-control", "no-cache"},
      {"user-agent",
       "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) " <>
         "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.135 " <>
         "Safari/537.36"},
      {"content-type", "application/json"},
      {"accept", "*/*"},
      {"origin", config |> url()},
      {"sec-fetch-site", "same-origin"},
      {"sec-fetch-mode", "cors"},
      {"sec-fetch-dest", "empty"},
      {"accept-language", "en-US,en;q=0.9"},
      {"cookie", "substack.sid=#{config.sid}"}
    ]
  end

  def collect(config, endpoint, args, opts \\ [])

  def collect(%Subscrape{} = config, %Endpoint{} = endpoint, args, opts),
    do: collect(config, {endpoint, []}, args, opts)

  def collect(
        %Subscrape{} = config,
        {
          %Endpoint{
            extract_key: extract_key,
            page_arg: page_arg
          },
          _
        } = endpoint,
        %{"limit" => limit} = args,
        opts
      )
      when is_binary(extract_key) and is_binary(page_arg) do
    Logger.debug(
      "START collecting...",
      subdomain: config.subdomain,
      endpoint: endpoint,
      args: args,
      opts: opts
    )

    case collect__internal(
           config,
           endpoint,
           args,
           &while_more/3,
           opts
         ) do
      {:ok, records} = result ->
        Logger.debug(
          "DONE collecting",
          subdomain: config.subdomain,
          endpoint: endpoint,
          limit: limit,
          total_records: Enum.count(records)
        )

        result

      {:error, error} = result ->
        Logger.debug(
          "FAIL collecting",
          subdomain: config.subdomain,
          endpoint: endpoint,
          limit: limit,
          error: error
        )

        result
    end
  end

  def while_more(_endpoint, %{"limit" => limit}, records)
      when is_integer(limit) and limit > 0 and is_list(records),
      do: length(records) == limit

  def collect_while(
        %Subscrape{} = config,
        {
          %Endpoint{
            extract_key: extract_key,
            page_arg: page_arg
          },
          _
        } = endpoint,
        args,
        test_fn,
        opts
      )
      when is_binary(extract_key) and is_binary(page_arg) do
    collect__internal(config, endpoint, args, test_fn, opts)
  end

  def collect_until(
        %Subscrape{} = config,
        {
          %Endpoint{
            extract_key: extract_key,
            page_arg: page_arg
          },
          _
        } = endpoint,
        args,
        test_fn,
        opts
      )
      when is_binary(extract_key) and is_binary(page_arg) do
    collect__internal(
      config,
      endpoint,
      args,
      fn endpoint, args, records -> !test_fn.(endpoint, args, records) end,
      opts
    )
  end

  defp until_limit(_endpoint, %{"limit" => limit}, records),
    do: Enum.count(records) < limit

  defp collect__internal(
         %Subscrape{} = config,
         {
           %Endpoint{
             extract_key: extract_key,
             page_arg: page_arg
           },
           _
         } = endpoint,
         args,
         test_fn,
         opts
       ) do
    with {:ok, %{^extract_key => records}} when is_list(records) <-
           request(config, endpoint, args, opts) do
      if test_fn.(endpoint, args, records) do
        case collect__internal(
               config,
               endpoint,
               args |> Map.put(page_arg, records |> List.last()),
               test_fn,
               opts
             ) do
          {:ok, rest} -> {:ok, records ++ rest}
          {:error, _} = result -> result
        end
      else
        {:ok, records}
      end
    end
  end

  def request(%Subscrape{} = config, endpoint, args, opts \\ []) do
    url = url(config, endpoint)

    Logger.debug(
      "START -- Substack request",
      url: url,
      args: args,
      opts: opts
    )

    case Cache.get(config, url, args) do
      {:hit, b} ->
        Logger.debug(
          "DONE -- Substack request -- CACHE HIT",
          endpoint: endpoint,
          args: args,
          opts: opts
        )

        {:ok, b |> Jason.decode!()}

      :miss ->
        case try_request(config, url, args, opts) do
          {:ok, %HTTPoison.Response{} = r} ->
            Logger.debug(
              "RECEIVED -- Substack request",
              endpoint: endpoint,
              args: args,
              opts: opts
            )

            process_response(config, r)

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
         _config,
         %HTTPoison.Response{
           status_code: 403,
           request_url: url,
           body: "Not authorized"
         }
       ) do
    {:error, %{status: 403, message: "403 Not authorized", request_url: url}}
  end

  defp process_response(
         %Subscrape{} = config,
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
          Cache.put(config, response)
          result
        else
          {:error, %{status: status, payload: payload}}
        end

      {:error, decode_error} ->
        Logger.error(
          "JSON FAIL -- decoding HTTP #{status} response from Substack",
          response: response,
          decode_error: decode_error
        )

        {:error, %{status: status, response: response}}
    end
  end

  defp try_request(%Subscrape{} = config, url, args, opts)
       when is_binary(url) and
              (is_nil(args) or is_map(args)) and
              is_list(opts) do
    request_options = opts |> Keyword.take(@httpoison_request_option_keys)
    params = request_options |> Keyword.get(:params, [])

    request = %HTTPoison.Request{
      method: if(is_nil(args), do: :get, else: :post),
      url: url |> HTTPoison.Base.build_request_url(params),
      headers: config |> headers(),
      body: if(is_nil(args), do: "", else: Jason.encode!(args)),
      params: params,
      # Shove `args` into the `options` so that we have it available for
      # logging if needed without having to pass it around too the whole time
      options: request_options |> Keyword.put(:args, args)
    }

    max_attempts = config |> Subscrape.opt!(opts, :max_retry_attempts)

    try_request(config, request, max_attempts, [])
  end

  defp try_request(%Subscrape{} = config, request, max_attempts, errors)
       when is_integer(max_attempts) and is_list(errors) and
              max_attempts >= 1 and length(errors) >= max_attempts do
    Logger.error(
      "#{max_attempts} Substack request attempts ALL FAILED, giving up",
      subdomain: config.subdomain,
      attempts: max_attempts,
      request: request,
      errors: errors
    )

    case errors do
      [error] -> {:error, error}
      _ -> {:error, "All retry attempts failed, see error log for details"}
    end
  end

  defp try_request(%Subscrape{} = config, request, max_attempts, errors)
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
          subdomain: config.subdomain,
          attempts: max_attempts,
          request: request,
          error: error
        )

        try_request(config, request, max_attempts, errors)
    end
  end
end

defmodule Subscrape.HTTP do
  @moduledoc """
  The meat of this whole sucker — HTTP requests with caching, retry, decoding
  and pagination support.

  Uses the `HTTPoison` Elixir HTTP client, which in turn wraps the [hackney][]
  Erlang HTTP client.

  [hackney]: https://github.com/benoitc/hackney

  This module is written specifically against the Substack API, but it should
  be treated as the development landscape for a general reference implementation
  of how we treat these nearly ubiquitous needs when interfacing with 3rd-party
  remote APIs.

  A point of particular note is that this module does **_no_** parallelization
  of requests. This is an intentional hack to avoid overloading Substack's
  rate limiting (it was originally parallel).

  Rate limiting is another very common issue when communicating with 3rd-party
  APIs. Rate limit configuration, detection, and adaptation is an important
  focus of further developing a general reference implementation, along with
  improved retry logic and configuration options.
  """
  @moduledoc author: "nrser"

  require Logger

  alias Subscrape.Cache
  alias Subscrape.Endpoint

  # SEE https://hexdocs.pm/httpoison/HTTPoison.Request.html
  @httpoison_request_option_keys ~w(
    timeout recv_timeout stream_to async proxy proxy_auth socks5_user
    socks5_pass ssl follow_redirect max_redirect params max_body_length
  )a

  @doc ~S"""
  The domain, given the `config.subdomain`.
  """
  @spec authority(Subscrape.t()) :: binary
  def authority(%Subscrape{} = config),
    do: "#{config.subdomain}.substack.com"

  @doc ~S"""
  Return the string URL for a request.

  All this does is call `uri/3` and pass it to `URI.to_string/1`, but it's
  the function you're more likely to use, so it's better explained here.

  ## Examples

  1.  **Get the subdomain URL**

      When called with no `path` or `query` returns the subdomain URL:

          iex> %Subscrape{subdomain: "test", sid: ""}
          ...> |> Subscrape.HTTP.url()
          "https://test.substack.com"

  2.  **Use a string `path`**

          iex> %Subscrape{subdomain: "test", sid: ""}
          ...> |> Subscrape.HTTP.url("/api/v1/subscriber/")
          "https://test.substack.com/api/v1/subscriber/"

  3.  **Use a `Subscrape.Endpoint` struct**

      `Subscrape.Endpoint` structs are accepted as the `path`:

          iex> %Subscrape{subdomain: "test", sid: ""}
          ...> |> Subscrape.HTTP.url(
          ...>   %Subscrape.Endpoint{format: "/api/v1/subscriber/"}
          ...> )
          "https://test.substack.com/api/v1/subscriber/"

      `Subscrape.Endpoint` structs support `EEx`-based templating:

          iex> endpoint = %Subscrape.Endpoint{
          ...>   format: "/api/v1/subscriber/<%= email %>/events",
          ...> }
          iex> %Subscrape{subdomain: "test", sid: ""}
          ...> |> Subscrape.HTTP.url(
          ...>   endpoint |> Subscrape.Endpoint.bind(email: "neil@nrser.com")
          ...> )
          "https://test.substack.com/api/v1/subscriber/neil%40nrser.com/events"

      Note the `"@" -> "%40"` substitution is done automatically in order to match
      Substack's observed URL encoding practices.

  4.  **Provide a `query`**

      Not sure if it's even in use right now, but support was added for some
      reason:

          iex> %Subscrape{subdomain: "test", sid: ""}
          ...> |> Subscrape.HTTP.url("/api/v1/subscriber/", %{x: 1, y: "two"})
          "https://test.substack.com/api/v1/subscriber/?x=1&y=two"

      `Keyword` lists are handled in addition to maps.
  """
  @spec url(
          Subscrape.t(),
          nil | binary | Subscrape.Endpoint.t(),
          nil | binary | list | map
        ) :: binary
  def url(%Subscrape{} = config, path \\ nil, query \\ nil),
    do: uri(config, path, query) |> URI.to_string()

  @doc ~S"""
  Like `url/3` (which actually uses this function!) but returns the `URI` struct
  instead of turning it into a string.

  IDK why this is exposed, really, but it is.
  """
  @spec uri(
          Subscrape.t(),
          nil | binary | Subscrape.Endpoint.t(),
          nil | binary | list | map
        ) :: URI.t()
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
    end
  end

  defp encode_query(query) do
    case query do
      nil -> nil
      str when is_binary(str) -> str
      enum when is_list(enum) or is_map(enum) -> URI.encode_query(enum)
    end
  end

  @doc ~S"""
  Get the HTTP headers to send with requests.

  We use the same ones for all requests. Fills in the _authority_, _user-agent_,
  and `cookie` headers from the `config`.

  ## Examples

      iex> %Subscrape{subdomain: "test", sid: "secret", user_agent: "My Script"}
      ...> |> Subscrape.HTTP.headers()
      [
        {"authority", "test.substack.com"},
        {"pragma", "no-cache"},
        {"cache-control", "no-cache"},
        {"user-agent", "My Script"},
        {"content-type", "application/json"},
        {"accept", "*/*"},
        {"origin", "https://test.substack.com"},
        {"sec-fetch-site", "same-origin"},
        {"sec-fetch-mode", "cors"},
        {"sec-fetch-dest", "empty"},
        {"accept-language", "en-US,en;q=0.9"},
        {"cookie", "substack.sid=secret"}
      ]
  """
  @spec headers(Subscrape.t()) :: [{binary, binary}, ...]
  def headers(%Subscrape{user_agent: user_agent} = config)
    when is_binary(user_agent) do
    [
      {"authority", config |> authority()},
      {"pragma", "no-cache"},
      {"cache-control", "no-cache"},
      {"user-agent", user_agent},
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

  @doc ~S"""
  A test function for `collect_while/5` that keeps going until the end, based on
  having a `"limit"` in the request args and returning `true` if the number of
  records returned is equal to that limit.
  """
  @spec while_more(Subscrape.Endpoint.t(), map, list) :: boolean
  def while_more(_endpoint, %{limit: limit}, records)
      when is_integer(limit) and limit > 0 and is_list(records),
      do: length(records) == limit

  @doc ~S"""
  Collect all records from a paginated endpoint, using `while_more/3` as the
  test function to `collect_while/5`.
  """
  @spec collect(
          Subscrape.t(),
          Subscrape.Endpoint.t(),
          map,
          keyword
        ) :: {:error, any} | {:ok, any}
  def collect(config, endpoint, %{limit: limit} = args, opts \\ [])
      when is_integer(limit) and limit > 0 do
    collect_while(
      config,
      endpoint,
      args,
      &while_more/3,
      opts
    )
  end

  @doc ~S"""
  Collect records from a paginated endpoint while a `test_fn` returns `true`
  for the previous page.

  ## Parameters

  -   `test_fn` — Called after each response is received that contains records
      (responses with zero records automatically terminate to simplify test
      logic).

      Passed the `endpoint`, `args` and records extracted from the response
      like:

          test_fn.(endpoint, args, records)

  ## Returns

  A list of all the extracted records.
  """
  @spec collect_while(
          Subscrape.t(),
          Subscrape.Endpoint.t(),
          nil | map,
          any,
          keyword
        ) :: {:error, any} | {:ok, list}
  def collect_while(
        config,
        %Endpoint{
          extract_key: extract_key,
          page_arg: page_arg
        } = endpoint,
        args,
        test_fn,
        opts
      )
      when is_atom(extract_key) and is_atom(page_arg) do
    with {:ok, %{^extract_key => records}} when is_list(records) <-
           request(config, endpoint, args, opts) do
      if length(records) > 0 && test_fn.(endpoint, args, records) do
        case collect_while(
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

  # Turn our arguments into an `HTTPoison.Request` struct.
  defp prepare_request(config, url, args, opts)
       when is_binary(url) and
              (is_nil(args) or is_map(args)) and
              is_list(opts) do
    request_options =
      opts
      |> Keyword.take(@httpoison_request_option_keys)
      # Shove `args` into the `options` so that we have it available for
      # logging if needed without having to pass it around too the whole time
      |> Keyword.put(:args, args)

    # These are query params, which we are not using at the moment, but support
    # is here should we need it
    params = request_options |> Keyword.get(:params, [])

    # Assume that `args` can be JSON encoded. This will raise if that fails.
    body = if is_nil(args), do: "", else: Jason.encode!(args)

    %HTTPoison.Request{
      method: if(is_nil(args), do: :get, else: :post),
      url: url |> HTTPoison.Base.build_request_url(params),
      headers: config |> headers(),
      body: body,
      params: params,
      options: request_options |> Keyword.put(:args, args)
    }
  end

  @doc ~S"""
  Make a request to the Substack API, with caching and retry support.

  The request URL is formed from the `config` and `endpoint`.

  > ℹ️ See `url/3`

  When `config.cache_root` is set (not `nil`), a hash is computed from the
  `config.subdomain`, the request URL, and the `args`, and the corresponding
  file path is first checked.

  > ℹ️ See `Subscrape.Cache.key/3` and `Subscrape.Cache.path/3`

  If that cache path exists, the file contents are JSON decoded and returned
  in a `{:ok, decoded_payload}` tuple.

  Otherwise, the max retry attempt count is calculated given the `opts` and
  `config` —

      opts[:max_retry_attempts]

  takes priority, else

      config.max_retry_attempts

  will be used — and the request/retry cycle is started.

  If _no_ HTTP requests receive a response before timing out, an

      {:error, reason}

  tuple is returned. `reason` will be one of:

  -   `HTTPoison.Error` — special case when max retry attempts is set to `1`.
      This make debugging easier by getting the single HTTP error back directly.

  -   A map consisting of:
      -   `message: binary` noting the failure.
      -   `request: HTTPoison.Request` that was attempted. Lot of info in here.
      -   `errors: [HTTPoison.Error]` containing the errors the occurred.

  Otherwise, the first response wins. What happens from here is still somewhat
  under development, but basically if both:

  1.  The response status is `200`
  2.  The response body is successfully JSON decoded

  then we cache the decoded payload (if `config.cache_root` is set)
  and return a tuple:

      {:ok, decoded_payload}

  Otherwise,

      {:error, reason}

  will be returned. As of writing, `reason` should a map with:

  -   `url: binary` — The request URL.
  -   `status: integer` — The HTTP status code.
  -   A `message: binary`, the request `body:`, or a JSON-decoded `payload:`.

  """
  def request(%Subscrape{} = config, endpoint, args, opts \\ [])
      when (is_nil(args) or is_map(args)) and is_list(opts) do
    url = url(config, endpoint)

    case Cache.get(config, url, args) do
      {:hit, b} ->
        {:ok, b |> Jason.decode!(keys: :atoms)}

      :miss ->
        request = prepare_request(config, url, args, opts)
        max_attempts = config |> Subscrape.opt!(opts, :max_retry_attempts)

        case try_request(config, request, max_attempts, []) do
          {:ok, %HTTPoison.Response{} = r} -> process_response(config, r)
          {:error, _} = r -> r
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
    {:error, %{url: url, status: 403, message: "403 Not authorized"}}
  end

  defp process_response(
         %Subscrape{} = config,
         %HTTPoison.Response{
           status_code: status,
           request_url: url,
           body: body
         } = response
       ) do
    case body |> Jason.decode(keys: :atoms) do
      {:ok, payload} = result ->
        if status == 200 do
          Cache.put(config, response)
          result
        else
          {:error, %{url: url, status: status, payload: payload}}
        end

      {:error, decode_error} ->
        {:error,
         %{url: url, status: status, body: body, json_error: decode_error}}
    end
  end

  # The termination case — the amount of `errors` accumulated is equal to the
  # number of `max_attempts`.
  #
  # Returns an `{:error, reason}` tuple.
  #
  # In the special case that there is only one error accumulated (and hence
  # `max_attempts` is 1) `reason` is simply that single error.
  #
  # This makes it simpler to develop and debug by turning `max_attempts` down to
  # 1 and getting the error back directly.
  #
  # Otherwise `reason` is a map with:
  #
  # -   `message:` — a binary message.
  # -   `request:` — the `request` argument, which holds the `url` and all the
  #     other info about the call.
  # -   `errors:` — list of the accumulated errors.
  #
  defp try_request(_config, request, max_attempts, errors)
       when is_integer(max_attempts) and is_list(errors) and
              max_attempts >= 1 and length(errors) >= max_attempts do
    case errors do
      # The special case — only a single request was made. Just pass through.
      [error] ->
        {:error, error}

      _ ->
        {:error,
         %{
           message: "#{max_attempts} Substack request attempts ALL FAILED",
           request: request,
           errors: errors
         }}
    end
  end

  # The looper — attempts a request, and if it fails, adds the error in the
  # `errors` lists and calls itself again.
  defp try_request(config, request, max_attempts, errors)
       when is_integer(max_attempts) and is_list(errors) and
              max_attempts >= 1 do
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

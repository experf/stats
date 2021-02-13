defmodule Subscrape.Cache do
  # Recursively expand maps into sorted lists of `[key, value]` lists in order to
  # produce a consistent `JSON` string.
  defp order_maps(x) do
    case x do
      map when is_map(map) ->
        map
        |> Enum.map(fn {key, value} -> [to_string(key), order_maps(value)] end)
        |> Enum.sort()

      list when is_list(list) ->
        list |> Enum.map(fn entry -> order_maps(entry) end)

      any ->
        any
    end
  end

  @spec key(Subscrape.t(), binary, nil | map) :: binary
  @doc ~S"""
  Form a string cache key identifying an API request.

  Depends on:
  1.  The newsletter in question (via subdomain in the `Subscrape` config).
  2.  The `url` the request will be sent to.
  3.  The `args` (if any) that will be posted (as `JSON`) in the request.
  """
  def key(%Subscrape{} = config, url, args) when is_binary(url) do
    json =
      %{subdomain: config.subdomain, url: url, args: args}
      |> order_maps()
      |> Jason.encode!()

    :crypto.hash(:md5, json) |> Base.encode16()
  end

  def filename(%Subscrape{} = config, url, args),
    do: key(config, url, args) <> ".json"

  @spec path(Subscrape.t(), binary, nil | map) :: binary
  @doc ~S"""
  Path to a cache file, see `key/3`.
  """
  def path(%Subscrape{cache_root: cache_root} = config, url, args)
      when is_binary(cache_root),
      do: Path.join(cache_root, filename(config, url, args))

  def get(%Subscrape{cache_root: cache_root} = config, url, args)
      when is_binary(cache_root) do
    path = path(config, url, args)

    if File.exists?(path), do: {:hit, File.read!(path)}, else: :miss
  end

  def get(%Subscrape{cache_root: cache_root}, _, _) when is_nil(cache_root),
    do: :miss

  def put(
        %Subscrape{cache_root: cache_root} = config,
        %HTTPoison.Response{} = response
      )
      when is_binary(cache_root) do
    unless File.exists?(cache_root), do: File.mkdir_p!(cache_root)

    path(config, response.request_url, response.request.options[:args])
    |> File.write!(response.body)

    :ok
  end

  @doc ~S"""
  Clear the cache by deleting the directory.
  """
  def clear(%Subscrape{cache_root: cache_root}) when is_binary(cache_root),
      do: cache_root |> File.rm_rf!()
end

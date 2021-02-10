defmodule Subscrape.Cache do
  defp order(map) when is_map(map),
    do:
      map
      |> Enum.map(fn {k, v} -> [to_string(k), order(v)] end)
      |> Enum.sort()

  defp order(list) when is_list(list),
    do: list |> Enum.map(fn entry -> order(entry) end)

  defp order(x), do: x

  def key(%Subscrape{} = client, url, args) when is_binary(url) do
    json =
      %{subdomain: client.subdomain, url: url, args: args}
      |> Map.put("__subdomain__", client.subdomain)
      |> Map.put("__url__", url)
      |> order()
      |> Jason.encode!()

    :crypto.hash(:md5, json) |> Base.encode16()
  end

  def filename(%Subscrape{} = client, url, args),
    do: key(client, url, args) <> ".json"

  def path(%Subscrape{cache_root: cache_root} = client, url, args)
      when is_binary(cache_root),
      do: Path.join(cache_root, filename(client, url, args))

  def get(%Subscrape{cache_root: cache_root} = client, url, args)
      when is_binary(cache_root) do
    path = path(client, url, args)

    if File.exists?(path), do: {:hit, File.read!(path)}, else: :miss
  end

  def get(%Subscrape{cache_root: cache_root}, _, _) when is_nil(cache_root),
    do: :miss

  def put(
        %Subscrape{cache_root: cache_root} = client,
        %HTTPoison.Response{} = response
      )
      when is_binary(cache_root) do
    unless File.exists?(cache_root), do: File.mkdir_p!(cache_root)

    path(client, response.request_url, response.request.options[:args])
    |> File.write!(response.body)

    :ok
  end
end

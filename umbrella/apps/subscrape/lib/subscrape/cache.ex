defmodule Subscrape.Cache do
  def key(%Subscrape{} = _client, url, args)
      when is_binary(url) and is_map(args) do
    "FAKE"
  end

  def get(key) when is_binary(key) do
    :miss
  end

  def get(%Subscrape{} = _client, _url, _args) do
    :miss
  end

  def put(key, value) when is_binary(key) and is_binary(value) do
    :ok
  end

  def put(%Subscrape{} = _client, %HTTPoison.Response{} = _response) do
    :ok
  end
end

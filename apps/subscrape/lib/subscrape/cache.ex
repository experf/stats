defmodule Subscrape.Cache do
  @type t :: %__MODULE__{
          root: binary,
          read_only: boolean
        }

  @doc ~S"""
  Holds cache configuration.
  """
  defstruct [
    :root,
    read_only: false
  ]

  @doc ~S"""
  Construct a `t:Subscrape.t/0` struct that hold the configuration.

  ## Parameters

  -   `arg` — depends on type:
      -   `t:binary/0` — becomes the `root` path.
      -   `t:map/0` — passed to `struct!/2`.
      -   `t:keyword/0` — turned into a map and called with that.

  ## Returns

  A `t:Subscrape.t/0` cache configuration struct.

  ## Examples

  1.  From just a `root` path:

          iex> Subscrape.Cache.new("/some/path")
          %Subscrape.Cache{root: "/some/path", read_only: false}

  2.  From a `Map`:

          iex> Subscrape.Cache.new(%{root: "/some/path", read_only: true})
          %Subscrape.Cache{root: "/some/path", read_only: true}

  3.  From `Keyword` list:

          iex> Subscrape.Cache.new(root: "/some/path", read_only: true)
          %Subscrape.Cache{root: "/some/path", read_only: true}
  """
  @spec new(binary | map | keyword) :: t()
  def new(arg)

  def new(root) when is_binary(root),
    do: __MODULE__ |> struct!(root: root)

  def new(props) when is_map(props),
    do: __MODULE__ |> struct!(props)

  def new(kwds) when is_list(kwds),
    do: kwds |> Enum.into(%{}) |> new()

  @doc ~S"""
  Just like `run/1` but maps `nil -> nil`.

  ## Examples

      iex> Subscrape.Cache.cast(nil)
      nil
  """
  @spec cast(nil | binary | keyword | map) :: nil | Subscrape.Cache.t()
  def cast(nil), do: nil
  def cast(x), do: new(x)

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

  @doc ~S"""
  Form a string cache key identifying an API request.

  Depends on:
  1.  The newsletter in question (via subdomain in the `Subscrape` config).
  2.  The `url` the request will be sent to.
  3.  The `args` (if any) that will be posted (as `JSON`) in the request.

  ## Returns

  `md5` hash encoded as a hexadecimal (base 16) string. Capital letters are
  used per `Base.encode16/2`.

  ## Examples

      iex> Subscrape.new(subdomain: "example", sid: "<none>")
      ...> |> Subscrape.Cache.key("/api/v1/subscriber/", %{})
      "80BA73FC3AEE2A320B5D65160EDBEC01"
  """
  @spec key(Subscrape.t(), binary, nil | map) :: binary
  def key(%Subscrape{} = config, url, args) when is_binary(url) do
    json =
      %{subdomain: config.subdomain, url: url, args: args}
      |> order_maps()
      |> Jason.encode!()

    :crypto.hash(:md5, json) |> Base.encode16()
  end

  @doc ~S"""
  Get the filename an API response will be stored at.

  ## Returns

  It's just `key/3` with `".json"` thrown on the end.

  ## Examples

      iex> Subscrape.new(subdomain: "example", sid: "<none>")
      ...> |> Subscrape.Cache.filename("/api/v1/subscriber/", %{x: 1, y: 2})
      "40BABC92D7FF09B2779038291332F7BD.json"
  """
  @spec filename(Subscrape.t(), binary, nil | map) :: binary
  def filename(%Subscrape{} = config, url, args),
    do: key(config, url, args) <> ".json"

  @doc ~S"""
  Path to a cache file, see `filename/3` and `key/3`.

  ## Examples

      iex> Subscrape.new(
      ...>   subdomain: "example",
      ...>   sid: "<none>",
      ...>   cache: "/some/path"
      ...> )
      ...> |> Subscrape.Cache.path("/api/v1/subscriber/", %{x: 1, y: 2})
      "/some/path/40BABC92D7FF09B2779038291332F7BD.json"
  """
  @spec path(Subscrape.t(), binary, nil | map) :: binary
  def path(
        %Subscrape{
          cache: %__MODULE__{
            root: root
          }
        } = config,
        url,
        args
      )
      when is_binary(root),
      do: Path.join(config.cache.root, filename(config, url, args))

  @doc ~S"""
  Read a string from the cache.

  ## Returns

  If

  1.  the cache is enabled (`config.cache` is not `nil`) and
  2.  the `path/3` exists,

  then you get a `{:hit, binary}` tuple.

  Otherwise, `:miss`.

  ## Examples

  Ok, this is kinda involved due to hittin' the file system...

      ...> # Setup a configuration, using a sub-directory of a system-provided
      ...> # temporary directory (at least on OSX, `System.tmp_dir!/0` is _not_
      ...> # per-process)...
      iex> config = Subscrape.new(
      ...>   subdomain: "example",
      ...>   sid: "<none>",
      ...>   cache: Path.join(System.tmp_dir!(), "subscrape/cache")
      ...> )
      ...>
      ...> # ...and clear that sub-dir out, to start FRESH!
      iex> config |> Subscrape.Cache.clear()
      ...>
      ...> # Our subdomain/url/args hash should be missing...
      iex> config |> Subscrape.Cache.get(
      ...>   "/api/v1/subscriber/",
      ...>   %{x: 1, y: 2}
      ...> )
      :miss
      ...>
      ...> # Now put something there...
      iex> config |> Subscrape.Cache.put(
      ...>   "/api/v1/subscriber/",
      ...>   %{x: 1, y: 2},
      ...>   "hey yo!"
      ...> )
      ...>
      ...> # ...and we can find it!
      iex> config |> Subscrape.Cache.get(
      ...>   "/api/v1/subscriber/",
      ...>   %{x: 1, y: 2}
      ...> )
      {:hit, "hey yo!"}

  """
  @spec get(Subscrape.t(), binary, nil | map) :: :miss | {:hit, binary}
  def get(config, url, args)

  def get(%Subscrape{cache: nil}, _, _), do: :miss

  def get(%Subscrape{cache: %__MODULE__{}} = config, url, args) do
    path = path(config, url, args)

    if File.exists?(path), do: {:hit, File.read!(path)}, else: :miss
  end

  @doc ~S"""
  Store a `HTTPoison` response.

  It has the `url` in it, and we add the `args` to the `.request.options`
  over in `Subscrape.HTTP.request/4`, so the `key/3` can be formed from
  only that and the `config`.

  ## Examples

  See `get/3` for a general idea.
  """
  @spec put(Subscrape.t(), nil | HTTPoison.Response.t()) :: :ok
  def put(%Subscrape{cache: nil}, _), do: :ok

  def put(%Subscrape{cache: %__MODULE__{read_only: true}}, _), do: :ok

  def put(
        %Subscrape{cache: %__MODULE__{root: root}} = config,
        %HTTPoison.Response{} = response
      )
      when is_binary(root) do
    unless File.exists?(root), do: File.mkdir_p!(root)

    path(config, response.request_url, response.request.options[:args])
    |> File.write!(response.body)

    :ok
  end

  @doc ~S"""
  Store a `t:binary/0`, specifying the `url` and `args` used to form the
  `key/3`.

  > 📢 This version was written just for testing. All code at time of writing
  > (2021-02-26) uses `put/2`.

  ## Examples

  See `get/3`
  """
  @spec put(Subscrape.t(), binary, nil | map, binary) :: :ok
  def put(
        %Subscrape{cache: %__MODULE__{root: root}} = config,
        url,
        args,
        value
      )
      when is_binary(root) and is_binary(url) and
             (is_nil(args) or is_map(args))and is_binary(value) do
    unless File.exists?(root), do: File.mkdir_p!(root)

    path(config, url, args) |> File.write!(value)

    :ok
  end

  @doc ~S"""
  Clear the cache by deleting the directory.
  """
  def clear(%Subscrape{
        cache: %__MODULE__{
          root: root
        }
      })
      when is_binary(root),
      do: root |> File.rm_rf!()
end

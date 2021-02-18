defmodule Subscrape do
  @moduledoc """
  Read data from the Substack API.
  """

  require Logger

  @type t :: %__MODULE__{
          subdomain: binary,
          sid: binary,
          user_agent: binary,
          subscriber_list_limit: integer,
          subscriber_events_limit: integer,
          cache_root: nil | binary,
        }

  @doc ~S"""
  The client configuration structure. Contains authentication credentials, as
  well as various configuration and default values.

  -   `:subdomain` — The 𝑠𝑢𝑏𝑑𝑜𝑚𝑎𝑖𝑛 string in `𝑠𝑢𝑏𝑑𝑜𝑚𝑎𝑖𝑛.substack.com`, which
      serves to identify the newsletter.

  -   `:sid` — Authentication token from Substack.

      The easiest way to get one is:

      1.  Log in to the site with your browser. I'm using Chromium, but there
          should be similar features available on Firefox, and probably even
          Safari.

      2.  Open up the developer tools to the _Network_ pane.

      3.  Filter by `XHR` requests and select a request that is hitting a url
          like:

          ```bash
          https://𝑠𝑢𝑏𝑑𝑜𝑚𝑎𝑖𝑛.substack.com/api/v1/…
          ```

      4.  Right click on the request row and select

          `Copy` → `Copy as cURL`

          > 📢 Chromium instructions, other browsers may vary.

      5.  Paste the resulting clipboard contents into a text file.

          It should look something like:

          ```bash
          curl 'https://skrim.substack.com/api/v1/subscriber/' \
            [...]
            -H 'cookie: __cfduid=[...]; substack.sid=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gR; ajs_anonymous_id=[...]' \
            [...]
          ```

          The part we want is the characters between `substack.sid=` and `;`.
          In this example case it would be

          ```bash
          eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gR
          ```

          That's your `sid`.

  -   `:user_agent` — What to put in the `User-Agent` header in `HTTP` requests.

      This defaults to one I got from a `Copy from cURL` some point way back.
      Not sure if it matters, haven't played with it.

  -   `:subscriber_list_limit` — Value to use for the `limit` option in
      `Subscrape.Subscriber.list/2` when called without one. Controls the
      maximum amount of event records per "page" we request.

      Defaults to `100`, which is the highest value Substack's API seems to
      accept.

  -   `:subscriber_events_limit` — Same as `:subscriber_list_limit`, but for
      the `Subscrape.Subscriber.Event` calls. Also defaults to `100`.

  -   `:max_retry_attempts` — Number of times to retry a failed `HTTP` request
      (which is usually due to timeout). Defaults to `3`.

  -   `:cache_root` — Where to keep a cache of response data. This is useful in
      development as Substack's API has rate limiting.
  """
  @enforce_keys [:subdomain, :sid]
  defstruct [
    :subdomain,
    :sid,
    user_agent:
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) " <>
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.135 " <>
        "Safari/537.36",
    subscriber_list_limit: 100,
    subscriber_events_limit: 100,
    max_retry_attempts: 3,
    cache_root: Application.get_env(:subscrape, __MODULE__, [])[:cache_root],
  ]

  def opt!(%__MODULE__{} = self, opts, key)
       when is_list(opts) and is_atom(key) do
    case opts |> Keyword.fetch(key) do
      {:ok, value} -> value
      :error -> self |> Map.fetch!(key)
    end
  end
end

defmodule Subscrape do
  @moduledoc """
  Documentation for `Subscrape`.
  """

  require Logger

  @type t :: %__MODULE__{
          subdomain: binary,
          sid: binary,
          user_agent: binary,
          subscriber_list_limit: integer,
          subscriber_events_limit: integer
        }

  @enforce_keys [:subdomain, :sid]
  defstruct [
    :subdomain,
    :sid,
    user_agent:
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) " <>
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.135 " <>
        "Safari/537.36",
    subscriber_list_limit: 100,
    # Web defaults to 20, but this seems to work. Even as high as 150 fails.
    subscriber_events_limit: 100,
    max_retry_attempts: 3,
  ]

  # Helpers Functions
  # ==========================================================================

  def opt!(%__MODULE__{} = self, opts, key)
       when is_list(opts) and is_atom(key) do
    case opts |> Keyword.fetch(key) do
      {:ok, value} -> value
      :error -> self |> Map.fetch!(key)
    end
  end

  defp remove_status(list) do
    list |> Enum.map(fn {email, {_, value}} -> {email, value} end)
  end
end

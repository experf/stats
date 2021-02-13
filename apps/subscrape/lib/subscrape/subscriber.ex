defmodule Subscrape.Subscriber do
  @moduledoc ~S"""
  Functions that send requests to the parts of the Substack API that deal with
  _subscribers_ (Substack's term for people who are on your email list).
  """

  require Logger

  alias Subscrape.HTTP
  alias Subscrape.Endpoint

  @get_endpoint %Endpoint{
    format: "/api/v1/subscriber/<%= email %>"
  }

  @list_endpoint %Endpoint{
    format: "/api/v1/subscriber/",
    extract_key: "subscribers",
    page_arg: "after",
  }

  @events_endpoint %Endpoint{
    format: "/api/v1/subscriber/<%= email %>/events",
    extract_key: "events",
    page_arg: "before",
  }

  defp remove_status({email, {_, value}}), do: {email, value}

  @doc ~S"""
  Get a list of _all_ subscribers. Iterates through them page-by-page,
  request-by-request, to get them all.


  """
  def list(%Subscrape{} = config, opts \\ []) do
    Logger.debug(
      "Requesting Substack subscriber list",
      subdomain: config.subdomain
    )

    {kwds, opts} = opts |> Keyword.split([:term, :filter, :limit])

    HTTP.collect(
      config,
      @list_endpoint,
      %{
        "term" => kwds |> Keyword.get(:term, ""),
        "filter" => kwds |> Keyword.get(:filter),
        "limit" => kwds |> Keyword.get(:limit, config.subscriber_list_limit),
      },
      opts
    )
  end

  @doc ~S"""
  Get a subscriber.

  ## Example

      > config |> Subscrape.Subscriber.get("neil@neilsouza.com")
      {:ok, %{
        "amount_paid" => 0,
        "bans" => [],
        "child_emails" => [],
        "created_at" => "2020-12-04T15:00:23.250Z",
        "data_updated_at" => "2021-02-10T05:33:37.068000000-08:00",
        "email" => "neil@neilsouza.com",
        "email_disabled" => true,
        "emails_opened" => 0,
        "emails_received" => 0,
        "expiry" => nil,
        "gift_email" => nil,
        "id" => 33673634,
        "is_group_parent" => false,
        "last_click" => nil,
        "last_open" => nil,
        "links_clicked" => nil,
        "parent_email" => nil,
        "podcast_email_disabled" => true,
        "publication_id" => 35776,
        "source" => "direct",
        "stripe_subscription_id" => nil,
        "type" => nil,
        "user_id" => 21777207
      }}

  """
  def get(%Subscrape{} = config, email, opts \\ []) when is_binary(email) do
    HTTP.request(
      config,
      {@get_endpoint, [email: email]},
      nil,
      opts
    )
  end

  def events(config, subscriber, opts \\ [])

  def events(%Subscrape{} = config, email, opts)
      when is_binary(email) do
    Logger.debug(
      "Requesting Substack events for subscriber",
      subdomain: config.subdomain,
      "subscriber.email": email
    )

    {kwds, opts} = opts |> Keyword.split([:limit])

    HTTP.collect(
      config,
      {@events_endpoint, [email: email]},
      %{
        "email" => email,
        "limit" => kwds |> Keyword.get(:limit, config.subscriber_events_limit),
      },
      opts
    )
  end

  def events(%Subscrape{} = config, %{"email" => email}, opts),
    do: events(config, email, opts)

  def events(%Subscrape{} = config, subscribers, opts)
      when is_list(subscribers) do
    results =
      for subscriber <- subscribers do
        email =
          case subscriber do
            %{"email" => email} when is_binary(email) -> email
            email when is_binary(email) -> email
          end

        {email, events(config, email, opts)}
      end

    {oks, errors} =
      results |> Enum.split_with(fn {_, {status, _}} -> status == :ok end)

    case errors do
      [] -> {:ok, oks |> Enum.map(&remove_status/1)}
      _ -> {:error, errors |> Enum.map(&remove_status/1)}
    end
  end

  def events(%Subscrape{} = config, :all, opts) do
    with {:ok, all} = list(config), do: events(config, all, opts)
  end
end

# defmodule Subscrape.Subscriber

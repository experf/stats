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
    page_key: "after",
  }

  @events_endpoint %Endpoint{
    format: "/api/v1/subscriber/<%= email %>/events",
    extract_key: "events",
    page_key: "before",
  }

  defp remove_status(list) do
    list |> Enum.map(fn {email, {_, value}} -> {email, value} end)
  end

  @doc ~S"""
  Get a list of _all_ subscribers. Iterates through them page-by-page,
  request-by-request, to get them all.
  """
  def list(%Subscrape{} = client, opts \\ []) do
    Logger.debug(
      "Requesting Substack subscriber list",
      subdomain: client.subdomain
    )

    HTTP.collect(
      client,
      @list_endpoint,
      %{
        "term" => "",
        "filter" => nil,
        "limit" => client |> Subscrape.opt!(opts, :subscriber_list_limit)
      },
      opts
    )
  end

  @doc ~S"""
  Get a subscriber.

  ## Example

      > client |> Subscrape.Subscriber.get("neil@neilsouza.com")
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
  def get(%Subscrape{} = client, email, opts \\ []) when is_binary(email) do
    HTTP.request(
      client,
      {@get_endpoint, [email: email]},
      nil,
      opts
    )
  end

  def events(client, email, opts \\ [])

  def events(%Subscrape{} = client, email, opts)
      when is_binary(email) do
    Logger.debug(
      "Requesting Substack events for subscriber",
      subdomain: client.subdomain,
      "subscriber.email": email
    )

    HTTP.collect(
      client,
      {@events_endpoint, [email: email]},
      %{
        "email" => email,
        "limit" => client |> Subscrape.opt!(opts, :subscriber_events_limit)
      },
      opts
    )
  end

  def events(%Subscrape{} = client, %{"email" => email}, opts),
    do: events(client, email, opts)

  def events(%Subscrape{} = client, subscribers, opts)
      when is_list(subscribers) do
    results =
      for subscriber <- subscribers do
        email =
          case subscriber do
            %{"email" => email} when is_binary(email) -> email
            email when is_binary(email) -> email
          end

        {email, events(client, email, opts)}
      end

    {events, errors} =
      results |> Enum.split_with(fn {_, {status, _}} -> status == :ok end)

    case errors do
      [] ->
        {:error, errors |> Enum.map(&remove_status/1)}

      _ ->
        {:ok, events |> Enum.map(&remove_status/1)}
    end
  end

  def events(%Subscrape{} = client, :all, opts) do
    with {:ok, all} = list(client), do: events(client, all, opts)
  end
end

# defmodule Subscrape.Subscriber

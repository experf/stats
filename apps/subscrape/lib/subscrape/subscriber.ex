defmodule Subscrape.Subscriber do
  @moduledoc ~S"""
  Functions that send requests to the parts of the Substack API that deal with
  _subscribers_ (Substack's term for people who are on your email list).
  """

  require Logger

  alias Subscrape.HTTP
  alias Subscrape.Endpoint
  alias Subscrape.Error

  @get_endpoint %Endpoint{
    format: "/api/v1/subscriber/<%= email %>"
  }

  @list_endpoint %Endpoint{
    format: "/api/v1/subscriber/",
    extract_key: "subscribers",
    page_arg: "after"
  }

  defp check_ok!(message, function_name, args) do
    case apply(__MODULE__, function_name, args) do
      {:ok, result} ->
        result

      {:error, error} ->
        raise Error, message: message, reason: error
    end
  end

  def email_for(email) when is_binary(email), do: email
  def email_for(%{"email" => email}) when is_binary(email), do: email

  @doc ~S"""
  Get a list of _all_ subscribers. Iterates through them page-by-page,
  request-by-request, to get them all.

  ## Examples

  Each _entry_ in the subscriber list looks something like:

      %{
        "email" => "xander@futureperfect.studio",
        "expiry" => nil,
        "id" => 16585900,
        "lastActivity" => %{
          "amount_paid" => 0,
          "data_updated_at" => "2021-02-12T11:18:21.497000000-08:00",
          "emails_opened" => 6,
          "emails_received" => 8,
          "last_click" => "2021-01-27T03:58:11.090000000+00:00",
          "last_open" => "2021-02-04T00:55:18.588000000+00:00",
          "links_clicked" => 51,
          "publication_id" => 35776,
          "source" => "direct",
          "user_id" => 16585900
        },
        "subscription_id" => 33518260,
        "type" => nil
      }

  > ❗ It's important to note that the `lastActivity.data_updated_at` field
  > does **_NOT_** seems to indicate when that user was last active, or in fact
  > any other externally useful piece of information — it's the _same_ _value_
  > for _every_ entry in the list.

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
        "limit" => kwds |> Keyword.get(:limit, config.subscriber_list_limit)
      },
      opts
    )
  end

  @doc ~S"""
  Version of `list/2` that raises on failure.
  """
  def list!(%Subscrape{} = config, opts \\ []),
    do:
      check_ok!(
        "Failed to get subscriber list",
        :list,
        [config, opts]
      )

  @doc ~S"""
  Get a subscriber.

  ## Example

      > config |> Subscrape.Subscriber.get("xander@futureperfect.studio")
      { :ok,
        %{
          "amount_paid" => 0,
          "bans" => [],
          "child_emails" => [],
          "created_at" => "2020-12-03T14:30:48.925Z",
          "crmData" => %{
            "is_comp" => false,
            "num_unique_web_posts_seen" => 2,
            "num_email_opens_last_7d" => 0,
            "user_photo_url" => "https://bucketeer-e05bbc84-baa3-437e-9518-adb32be77984.s3.amazonaws.com/public/images/b91a477a-274a-4264-a276-6760d7cd6e03_512x512.png",
            "num_comments_last_7d" => 0,
            "subscription_id" => 33518260,
            "is_founding" => false,
            "num_web_post_views" => 4,
            "num_shares_last_7d" => 0,
            "num_subs_gifted" => 0,
            "user_email_address" => "xander@futureperfect.studio",
            "is_group_member" => false,
            "num_unique_email_posts_seen_last_7d" => 0,
            "user_id" => 16585900,
            "subscription_created_at" => "2020-12-03T14:30:48.925Z",
            "unsubscribed_at" => nil,
            "activity_rating" => 4,
            "subscription_expires_at" => nil,
            "data_updated_at" => "2021-02-13T02:03:07.624Z",
            "md5" => "cd2ede1dc72e782ad99a22831b4fd695",
            "is_paying_regular_member" => false,
            "total_revenue_refunded" => 0,
            "first_payment_at" => nil,
            "num_email_opens_last_30d" => 7,
            "subdomain" => "skrim",
            "free_attribution" => "import",
            "num_shares" => 0,
            "days_active_last_30d" => 4,
            "publication_id" => 35776,
            "num_web_post_views_last_7d" => 0,
            "subscription_interval" => "free",
            "num_unique_web_posts_seen_last_7d" => 0,
            "num_email_opens" => 21,
            "num_unique_email_posts_seen_last_30d" => 2,
            "is_subscribed" => false,
            "num_invoices_paid" => 0,
            "num_comments" => 0,
            "num_unique_email_posts_seen" => 6,
            "num_comments_last_30d" => 0,
            "group_parent_subscription_id" => nil,
            "num_shares_last_30d" => 0,
            "multipub_parent_subscription_id" => nil,
            "num_web_post_views_last_30d" => 4,
            "total_revenue_generated" => 0,
            "is_gift" => false,
            "user_name" => "Parodos",
            "email_disabled_at" => nil,
            "paid_attribution" => nil,
            "num_unique_web_posts_seen_last_30d" => 2
          }
          "data_updated_at" => "2021-02-15T00:07:42.864000000-08:00",
          "email" => "xander@futureperfect.studio",
          "email_disabled" => false,
          "emails_opened" => 6,
          "emails_received" => 8,
          "expiry" => nil,
          "gift_email" => nil,
          "id" => 33518260,
          "is_group_parent" => false,
          "last_click" => "2021-01-27T03:58:11.090000000+00:00",
          "last_open" => "2021-02-04T00:55:18.588000000+00:00",
          "links_clicked" => 51,
          "parent_email" => nil,
          "podcast_email_disabled" => false,
          "publication_id" => 35776,
          "source" => "direct",
          "stripe_subscription_id" => nil,
          "type" => nil,
          "user_id" => 16585900
        }
      }

  """
  def get(%Subscrape{} = config, email, opts \\ []) when is_binary(email) do
    HTTP.request(
      config,
      {@get_endpoint, [email: email]},
      nil,
      opts
    )
  end

  @doc ~S"""
  Version of `get/3` that raises on failure.
  """
  def get!(%Subscrape{} = config, email, opts \\ []) when is_binary(email),
    do:
      check_ok!(
        "Failed to get subscriber #{email}",
        :get,
        [config, email, opts]
      )

  defp active_since?(subscriber_list_entry, %DateTime{} = since) do
    ["last_click", "last_open"]
    |> Enum.any?(fn key ->
      case subscriber_list_entry |> get_in(["lastActivity", key]) do
        nil ->
          false

        iso8601_s when is_binary(iso8601_s) ->
          case iso8601_s |> DateTime.from_iso8601() do
            {:ok, activity_datetime, _offset_sec} ->
              case DateTime.compare(activity_datetime, since) do
                :gt -> true
                _ -> false
              end

            {:error, reason} ->
              Logger.error(
                "ISO 8601 parse failed on `lastActivity.#{key}`",
                value: iso8601_s,
                reason: reason,
                subscriber_list_entry: subscriber_list_entry
              )

              false
          end
      end
    end)
  end

  @doc ~S"""
  Filters a subscriber list to entries with "activity" after a `since` argument.

  Useful for limiting `events/3` calls to only subscribers that have done
  something since the last pull.

  > ### ❗WARNING❗ ###
  >
  > Recent activity, as visible in the subscriber list entries, is
  > limited to `"Clicked link in email"` and `"Opened email"` events.
  >
  > We have not yet found any efficient way of detecting new subscriber events
  > of any other type.

  ## Parameters

  -   `subscriber_list` — List of maps as returned from `list/2`.

  -   `since` — A `DateTime` that either `lastActivity.last_click` or
      `lastActivity.last_open` must be *strictly* greater than.

  ## Returns

  A sub-list of `subscriber_list`.
  """

  def active_since(subscriber_list, %DateTime{} = since)
      when is_list(subscriber_list),
      do:
        subscriber_list |> Enum.filter(fn sub -> active_since?(sub, since) end)
end

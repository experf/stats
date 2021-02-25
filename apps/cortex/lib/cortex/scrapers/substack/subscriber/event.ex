defmodule Cortex.Scrapers.Substack.Subscriber.Event do
  @moduledoc ~S"""
  Support for `Cortex.Scrapers.Substack` dealing with Substack subscriber
  _event_ data entities.

  Details of _Substack subscriber events_ can be found in
  `Subscrape.Subscriber.Event`.
  """

  require Logger

  alias Cortex.Ext
  alias Cortex.Scrapers.Substack

  @type props :: %{
          app: binary,
          type: binary,
          subtype: binary,
          email: binary,
          src: Subscrape.Subscriber.Event.t()
        }

  @type t :: {DateTime.t(), props}

  @subtypes %{
    "Clicked link in email" => "email.link.click",
    "Dropped email" => "sub.drop",
    "Free Signup" => "sub.new",
    "Opened email" => "email.open",
    "Post seen" => "post.view",
    "Received email" => "email.receive"
  }

  @produce_chunk_size 100

  # Helpers
  # ==========================================================================

  # Helps `scrape_new!/2` and `scrape_updated!/2` map over `to_cortex_event/3`.
  #
  defp to_cortex_events(events, email, app) do
    events |> Enum.map(fn e -> e |> to_cortex_event(email, app) end)
  end

  # Extracts the most recent `t:DateTime.t/0` from a non-empty list of Cortex
  # events. Used to update `last_subscriber_event_at` in the state.
  defp most_recent_event_at(events) do
    events
    |> Enum.max_by(&elem(&1, 0), DateTime)
    |> elem(0)
  end

  # Grab the most recent subscriber email from a non-empty list of Cortex
  # events, in order to update `last_subscriber_email` in the state.
  #
  # Because:
  #
  # 1.  Subscribers are ordered with most recent first.
  # 2.  Events are ordered by subscriber.
  # 3.  New subscribers are listed before updated ones.
  #
  # This simply amounts to the email on the first event.
  #
  defp most_recent_subscriber_email([{_, %{email: email}} | _]), do: email

  # Update the `t:Cortex.Scrapers.Substack.t/0` struct when there were no
  # events found, hence no update.
  #
  defp update(%Substack{} = this, []), do: this

  # Update the `t:Cortex.Scrapers.Substack.t/0` struct when there were events
  # found, setting `last_subscriber_email` and `last_subscriber_event_at`.
  #
  defp update(%Substack{} = this, events) when is_list(events) do
    %{
      this
      | last_subscriber_email: most_recent_subscriber_email(events),
        last_subscriber_event_at: most_recent_event_at(events)
    }
  end


  # Public API
  # ==========================================================================

  @spec subtype(binary) :: binary
  def subtype(text) when is_binary(text),
    do: @subtypes |> Map.get(text, "other")

  @doc ~S"""
  Convert a Substack subscriber event (as returned from
  `Subscrape.Subscriber.Event` functions) into a value for
  `Cortex.Events.produce/2` (where it feeds into the Kafka event stream).

  ## Returns

  A 2-element `Tuple` of:

  1.  Event timestamp parsed as a `DateTime`. This assigns this time to the
      event in liu of the time at which the data is inserted.
  2.  `subscriber_email`, `app` and the `substack_event` data combined into a
      `t:props/0` map. This is how the record will appear in the event stream.

  ## Examples

      iex> %{
      ...>  post_title: "Experiential art, cloud gaming, and a mind-altering mirrored dome",
      ...>  post_url: "/p/experiential-art-cloud-gaming-and",
      ...>  text: "Opened email",
      ...>  timestamp: "2020-12-22T18:11:49.950000000+00:00",
      ...>  url: nil
      ...> }
      ...> |> Cortex.Scrapers.Substack.Subscriber.Event.to_cortex_event(
      ...>  "xander@futureperfect.studio",
      ...>  "milk"
      ...> )
      {
        ~U[2020-12-22 18:11:49.950000Z],
        %{
          app: "milk",
          type: "substack.subscriber.event",
          subtype: "email.open",
          email: "xander@futureperfect.studio",
          src: %{
            post_title: "Experiential art, cloud gaming, and a mind-altering mirrored dome",
            post_url: "/p/experiential-art-cloud-gaming-and",
            text: "Opened email",
            timestamp: "2020-12-22T18:11:49.950000000+00:00",
            url: nil
          }
        }
      }
  """
  @spec to_cortex_event(Subscrape.Subscriber.Event.t(), binary, binary) :: t()
  def to_cortex_event(
        %{text: text, timestamp: iso8601} = substack_event,
        subscriber_email,
        cortex_app
      ) do
    {
      iso8601 |> Ext.DateTime.from_iso8601!(),
      %{
        app: cortex_app,
        type: "substack.subscriber.event",
        subtype: text |> subtype(),
        email: subscriber_email,
        src: substack_event
      }
    }
  end

  @doc ~S"""
  Given a list of subscribers that appear to have been added _since_ the last
  scrape (per `last_subscriber_email` in the `Substack` struct), scrape
  _all_ of their events.

  ## Returns

  A list of `t:t/0` values ready for `Cortex.Events.produce/2`.

  See `to_cortex_event/3` for details.
  """
  @spec scrape_new!(
          Substack.t(),
          [Subscrape.Subscriber.t()]
        ) :: [t()]
  def scrape_new!(substack, subscriber_list)

  def scrape_new!(_self, []), do: []

  def scrape_new!(
        %Substack{app: app, client: client},
        subscriber_list
      ) do
    subscriber_list
    |> Enum.flat_map(fn %{email: email} ->
      client
      |> Subscrape.Subscriber.Event.all!(email)
      |> to_cortex_events(email, app)
    end)
  end

  @doc ~S"""
  Given a list of subscribers that appear to have been active _since_ the last
  scrape (per `last_subscriber_event_at` in the `Substack` struct), scrape
  each of their events occurring after `last_subscriber_event_at`.

  ## Returns

  A list of `t:t/0` values ready for `Cortex.Events.produce/2`.

  See `to_cortex_event/3` for details.
  """
  @spec scrape_updated!(
          Substack.t(),
          [Subscrape.Subscriber.t()]
        ) :: [t()]
  def scrape_updated!(substack, subscriber_list)

  def scrape_updated!(_, []), do: []

  def scrape_updated!(
        %Substack{
          app: app,
          client: client,
          last_subscriber_event_at: %DateTime{} = last_subscriber_event_at
        },
        subscriber_list
      )
      when is_binary(app) and is_binary(client) and is_list(subscriber_list) do
    subscriber_list
    |> Enum.flat_map(fn %{email: email} ->
      client
      |> Subscrape.Subscriber.Event.since!(email, last_subscriber_event_at)
      |> to_cortex_events(email, app)
    end)
  end

  @doc ~S"""
  Do the scrape, returning an updated `Cortex.Scrapers.Substack.t/0` struct.
  """
  def scrape!(
        %Substack{
          last_subscriber_email: last_subscriber_email,
          last_subscriber_event_at: last_subscriber_event_at
        } = this
      ) do
    start_time = System.monotonic_time(:millisecond)

    {new_subs_list, updated_subs_list} =
      this |> Substack.Subscriber.scrape_list!()

    new_events = this |> scrape_new!(new_subs_list)
    updated_events = this |> scrape_updated!(updated_subs_list)

    events = new_events ++ updated_events

    # Need to do this because sending them all at once can overload the max
    # message size.
    #
    # TODO  In the future, this could be moved into `Cortex.Events`, where
    #       the size of the data could be estimated once it was encoded, and
    #       the batch could be broken up dynamically to a minimum number of
    #       requests.
    #
    #       But for now, fuck it, this works.
    #
    for chunk <- events |> Enum.chunk_every(@produce_chunk_size),
        do: chunk |> Cortex.Events.produce!()

    elapsed_ms = System.monotonic_time(:millisecond) - start_time

    this = this |> update(events)

    Logger.info(
      "Scraped Substack subscriber events",
      elapsed: "#{elapsed_ms}ms",
      subdomain: this.client.subdomain,
      total: events |> length(),
      new: new_events |> length(),
      are_new_since: last_subscriber_email,
      updated: updated_events |> length(),
      are_updated_since: last_subscriber_event_at,
      most_recent_subscriber: this.last_subscriber_email,
      most_recent_event_at: this.last_subscriber_event_at
    )

    this
  end
end

defmodule Cortex.Scrapers.Substack.Subscriber do
  @moduledoc ~S"""
  Support for `Cortex.Scrapers.Substack` dealing with Substack subscribers.
  """

  alias Cortex.Scrapers.Substack

  # This is the initial-state case, when there is no state information about
  # what events have been scraped.
  #
  # In this case, we scrape _everyone_. It takes some time.
  #
  def scrape_list!(%Substack{
        client: client,
        last_subscriber_event_at: nil
      }),
      do: {client |> Subscrape.Subscriber.list!(), []}

  def scrape_list!(%Substack{
        client: client,
        last_subscriber_event_at: %DateTime{} = last_subscriber_event_at,
        last_subscriber_email: last_subscriber_email
      }) do
    {new_subs, previously_scraped_subs} =
      client
      |> Subscrape.Subscriber.list!()
      |> Enum.split_while(fn %{email: email} ->
        email != last_subscriber_email
      end)

    updated_subs =
      previously_scraped_subs
      |> Subscrape.Subscriber.active_since(last_subscriber_event_at)

    {new_subs, updated_subs}
  end
end

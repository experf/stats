defmodule Subscrape.Subscriber.Event do
  @moduledoc ~S"""
  Functions for working with subscriber events, as returned from
  `Subscrape.Subscriber.events/3`.
  """

  require Logger

  alias Subscrape.Helpers
  alias Subscrape.Endpoint
  alias Subscrape.HTTP
  alias Subscrape.Subscriber

  @type subscriber :: binary | map

  @endpoint %Endpoint{
    format: "/api/v1/subscriber/<%= email %>/events",
    extract_key: "events",
    page_arg: "before"
  }

  def datetime_for(%{"timestamp" => iso8601_s}) do
    with {:ok, datetime, _} <- DateTime.from_iso8601(iso8601_s),
         do: {:ok, datetime}
  end

  @spec after?(map, DateTime.t()) :: boolean
  def after?(event, %DateTime{} = compared_to),
    do: Helpers.after?(datetime_for(event), compared_to)

  @spec collect_while(
          Subscrape.t(),
          subscriber(),
          map,
          (any, any, any -> any),
          maybe_improper_list
        ) :: {:error, any} | {:ok, any}
  def collect_while(
        config,
        subscriber,
        args,
        test_fn,
        opts \\ []
      )
      when is_list(opts) and is_function(test_fn, 3) do
    email = Subscriber.email_for(subscriber)

    HTTP.collect_while(
      config,
      {@endpoint, [email: email]},
      args |> Map.put("email", email),
      test_fn,
      opts
    )
  end

  @spec all(Subscrape.t(), subscriber(), keyword) ::
          {:error, any} | {:ok, [map]}
  def all(config, subscriber, opts \\ []) do
    {kwds, opts} = opts |> Keyword.split([:limit])

    collect_while(
      config,
      subscriber,
      %{
        "limit" => kwds |> Keyword.get(:limit, config.subscriber_events_limit)
      },
      &HTTP.while_more/3,
      opts
    )
  end

  @spec all!(Subscrape.t(), subscriber(), keyword) ::
          {:error, any} | {:ok, [map]}
  def all!(config, subscriber, opts \\ []),
    do:
      Helpers.check_ok!(
        {"Failed to get all events for ~s", [subscriber]},
        __MODULE__,
        :all,
        [config, subscriber, opts]
      )

  # def map(config, subscribers, opts \\ [])
  #     when is_list(subscribers) and is_list(opts) do

  # end
end

defmodule Subscrape.Subscriber.Event do
  @moduledoc ~S"""
  Functions for working with subscriber events.
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
  def after?(event, %DateTime{} = datetime),
    do: Helpers.after?(datetime_for(event), datetime)

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
    {kwds, opts} = opts |> Keyword.split([:limit])
    email = Subscriber.email_for(subscriber)

    HTTP.collect_while(
      config,
      @endpoint |> Endpoint.bind(email: email),
      %{
        "email" => email,
        "limit" => kwds |> Keyword.get(:limit, config.subscriber_events_limit),
      } |> Map.merge(args),
      test_fn,
      opts
    )
  end

  @doc ~S"""
  Get all _events_ associated with a subscriber.

  Each _event_ looks something like:

      %{
        "post_title" => "Immersive film festival, art-making and AI, and proto-VR from 1975",
        "post_url" => "/p/immersive-film-festival-art-making",
        "text" => "Opened email",
        "timestamp" => "2021-02-04T00:55:18.588000000+00:00",
        "url" => nil
      }

  ## Parameters

  -   `config` — A `Subscrape` struct holding the client configuration.
  -   `subscriber` — One of the following:

      1.  A subscriber email address binary.

      2.  A map with a `"email"` key with binary value, such as returned
          from `get/3` or an entry in a subscriber `list/2`.

      3.  A list of (1) or (2).

      4.  `:all` to first pull the subscriber `list/2`, then get all events for
          each entry. This is mostly for development use and can take quite a
          while.

  ## Returns

  `{:ok, result}` on success, `{:error, reason}` on failure.

  The form of `result` is dictated by the `subscriber` argument:

  1.  A single subscriber (options (1) or (2) in the `subscriber` parameter
      description):

      List of _event_ maps.

  2.  Multiple subscribers (options (3) or (4) in the `subscriber` parameter
      description):

      List of `{email, [event, event, ...]}` pairs.

  ## Examples

  Get all of Xander's events, which may take multiple requests in serial:

      >>> config |> Subscrape.Subscriber.Event.all("xander@futureperfect.studio")
      { :ok,
        [
          %{
            "post_title" => "Immersive film festival, art-making and AI, and proto-VR from 1975",
            "post_url" => "/p/immersive-film-festival-art-making",
            "text" => "Opened email",
            "timestamp" => "2021-02-04T00:55:18.588000000+00:00",
            "url" => nil
          },
          ...
        ]
      }
  """
  @spec all(Subscrape.t(), subscriber(), keyword) ::
          {:error, any} | {:ok, [map]}
  def all(config, subscriber, opts \\ []) do
    collect_while(
      config,
      subscriber,
      %{},
      &HTTP.while_more/3,
      opts
    )
  end

  @doc ~S"""
  Version of `all/3` that raises on failure.
  """
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

  # ## Examples
  #
  # Get all of both Xander and Neil's events, which also precedes totally in
  # serial:
  #
  #     >>> config
  #     ... |> Subscrape.Subscriber.Event.map(
  #     ...   ["xander@futureperfect.studio", "neil@neilsouza.com"]
  #     ... )
  #     { :ok,
  #       [
  #         {"xander@futureperfect.studio",
  #           [
  #             %{
  #               "post_title" => "Immersive film festival, art-making and AI, and proto-VR from 1975",
  #               "post_url" => "/p/immersive-film-festival-art-making",
  #               "text" => "Opened email",
  #               "timestamp" => "2021-02-04T00:55:18.588000000+00:00",
  #               "url" => nil
  #             },
  #             ...
  #           ]
  #         },
  #         {"neil@neilsouza.com", []}
  #       ]
  #     }
  #
  @spec map(Subscrape.t(), [subscriber()], keyword) :: list
  def map(config, subscribers, opts \\ [])
      when is_list(subscribers) and is_list(opts) do
    subscribers
    |> Enum.map(fn subscriber ->
      {subscriber, all!(config, subscriber, opts)}
    end)
  end

  def all_after?(since),
    do: fn _endpoint, _args, events ->
      events |> Enum.all?(&(after? &1, since))
    end

  @doc ~S"""
  Get subscriber events that are timestamped strictly _after_ the `since`
  argument.

  Uses `collect_while/5` to only request additional event pages while all the
  events on the previous page qualify.
  """
  def since(config, subscriber, since, opts \\ []) do
    with {:ok, events} <-
           collect_while(
             config,
             subscriber,
             %{},
             all_after?(since),
             opts
           ),
         do: {:ok, events |> Enum.take_while(&(after? &1, since))}
  end

  @doc ~S"""
  Version of `since/4` that raises on failure.
  """
  def since!(config, subscriber, since, opts \\ []),
    do: Helpers.check_ok!(
      {"Failed to get events since ~s for ~s", [since, subscriber]},
      __MODULE__,
      :since,
      [config, subscriber, since, opts]
    )
end

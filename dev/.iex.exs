import Ecto.Query

# Make it quicker to work in the REPL

alias Cortex.Accounts
alias Cortex.Accounts.{User, UserToken}
alias Cortex.Trackers
alias Cortex.Trackers.{Link}
alias Cortex.OpenGraph
alias Cortex.Repo

alias Cortex.Scrapers
alias Cortex.Scrapers.Scraper
alias Cortex.Scrapers.Substack
alias Subscrape.Subscriber

defmodule M do
  def ok!({:ok, value}), do: value
end

defmodule Dump do
  def json(value, name) do
    path = "tmp/#{name}.json"
    content = value |> Jason.encode!(pretty: true)
    File.write!(path, content)
  end
end

defmodule SS do
  def app(),
    do: "milk"

  def config() do
    subdomain = System.get_env("STATS_MILK_SUBDOMAIN")
    sid = System.get_env("STATS_MILK_SID")

    Subscrape.new(subdomain: subdomain, sid: sid)
  end

  def bad_config() do
    %Subscrape{
      subdomain: System.get_env("STATS_MILK_SUBDOMAIN"),
      sid: "",
      cache: nil,
      max_retry_attempts: 1,
    }
  end

  def xander_email(), do: "xander@futureperfect.studio"
  def neil_email(), do: "neil@neilsouza.com"

  defmodule Events do
    def all() do
      with {:ok, events} <- SS.config() |> Subscrape.Subscriber.events(:all) do
        events
        |> Enum.map(fn {_, evs} -> evs end)
        |> Enum.concat()
      end
    end
  end

  # def load_xander(),
  #   do: Scrapers.Substack.scrape_subscriber_events(
  #     client(),
  #     app(),
  #     email()
  #   )

  # def load_all(),
  #   do: Scrapers.Substack.scrape(client(), app())
end

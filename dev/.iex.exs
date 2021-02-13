import Ecto.Query

# Make it quicker to work in the REPL

alias Cortex.Accounts
alias Cortex.Accounts.{User, UserToken}
alias Cortex.Trackers
alias Cortex.Trackers.{Link}
alias Cortex.OpenGraph
alias Cortex.Repo

alias Cortex.Clients
alias Cortex.Scrapers

defmodule SS do
  def app(),
    do: "milk"

  def config() do
    subdomain = System.get_env("STATS_MILK_SUBDOMAIN")
    sid = System.get_env("STATS_MILK_SID")

    %Subscrape{subdomain: subdomain, sid: sid}
  end

  def xander_email(), do: "xander@futureperfect.studio"
  def neil_email(), do: "neil@neilsouza.com"

  # def load_xander(),
  #   do: Scrapers.Substack.scrape_subscriber_events(
  #     client(),
  #     app(),
  #     email()
  #   )

  # def load_all(),
  #   do: Scrapers.Substack.scrape(client(), app())
end

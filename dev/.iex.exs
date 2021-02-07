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

  def client() do
    subdomain = System.get_env("STATS_OSMOSE_SUBDOMAIN")
    sid = System.get_env("STATS_OSMOSE_SID")

    %Clients.Substack{subdomain: subdomain, sid: sid}
  end

  def email(),
    do: "xander@futureperfect.studio"

  def load_xander(),
    do: Scrapers.Substack.scrape_subscriber_events(
      client(),
      app(),
      email()
    )

  def load_all(),
    do: Scrapers.Substack.scrape(client(), app())
end

import Ecto.Query

# Make it quicker to work in the REPL

alias Cortex.Accounts
alias Cortex.Accounts.{User, UserToken}
alias Cortex.Trackers
alias Cortex.Trackers.{Link}
alias Cortex.OpenGraph
alias Cortex.Repo

alias Cortex.Clients.Substack

defmodule M do
  def ss() do
    subdomain = System.get_env("STATS_OSMOSE_SUBDOMAIN")
    sid = System.get_env("STATS_OSMOSE_SID")

    %Substack{subdomain: subdomain, sid: sid}
  end
end

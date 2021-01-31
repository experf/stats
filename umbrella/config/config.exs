# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
use Mix.Config

# Configure Mix tasks and generators
config :cortex,
  ecto_repos: [Cortex.Repo]

config :cortex_web,
  ecto_repos: [Cortex.Repo],
  generators: [context_app: :cortex]

# Configures the endpoints

config :cortex_web, CortexWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "grHK+/3KfRvohPFG5CA1gOcqBuRRU71Ngc9bvZkIbZqNSg1j5bN6tDJTxmIst+Gq",
  render_errors: [view: CortexWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Cortex.PubSub,
  live_view: [signing_salt: "8qUj7PUk"]

config :cortex_web, CortexWeb.LinkEndpoint,
  url: [host: "localhost"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :cortex, Cortex.OpenGraph.Metadata,
  schema_json: File.read!("#{__DIR__}/../apps/cortex_web/assets/static/schemas/ogp.me.schema.json")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

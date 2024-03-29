use Mix.Config

# Load `//dev/.env` if it exists
dev_env_path = Path.expand("../dev/.env", __DIR__)
if File.exists?(dev_env_path), do: Dotenv.load!(dev_env_path)

# Configure your database
config :cortex, Cortex.Repo,
  username: "postgres",
  # password: "postgres",
  database: "cortex_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :cortex_web, CortexWeb.AppEndpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../apps/cortex_web/assets", __DIR__)
    ]
  ]

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Note that this task requires Erlang/OTP 20 or later.
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :cortex_web, CortexWeb.AppEndpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/cortex_web/(live|views)/.*(ex)$",
      ~r"lib/cortex_web/templates/.*(eex)$"
    ]
  ]

config :logger,
  compile_time_purge_matching: [
    [module: Subscrape.HTTP, level_lower_than: :info],
    [module: Subscrape.Subscriber, level_lower_than: :info],
  ]

config :logger, :console,
  format: {Cortex.Logging.DevFormatter, :format},
  metadata: :all # Filter in `Cortex.Logging.DevFormatter`


# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

config :cortex, Cortex.Mailer,
  adapter: Swoosh.Adapters.Mailgun,
  api_key: System.get_env("STATS_MAILGUN_API_KEY"),
  domain: System.get_env("STATS_MAILGUN_DOMAIN")

config :cortex_web, CortexWeb.LinkEndpoint,
  http: [port: 4001],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../apps/cortex_web/assets", __DIR__)
    ]
  ]

config :subscrape, Subscrape,
  cache: %{
    root: Path.expand("../tmp/cache/subscrape/2021-02-24", __DIR__),
    read_only: true
  }

import_if_exists = fn rel_path ->
  if File.exists?("#{__DIR__}/#{rel_path}"), do: import_config(rel_path)
end

import_if_exists.("dev/#{System.get_env("USER")}.exs")

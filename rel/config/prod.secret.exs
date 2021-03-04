# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
use Mix.Config

database_url =
  System.get_env("CORTEX_DATABASE_URL") ||
    raise """
    environment variable CORTEX_DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :cortex, Cortex.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

secret_key_base =
  System.get_env("CORTEX_WEB_SECRET") ||
    raise """
    environment variable CORTEX_WEB_SECRET is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :cortex_web, CortexWeb.AppEndpoint,
  http: [
    port: String.to_integer(System.get_env("CORTEX_WEB_PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  url: [
    scheme: "https",
    host: System.get_env("CORTEX_WEB_HOST") || "stats.expand.live",
    port: 443,
  ],
  secret_key_base: secret_key_base,
  server: true,
  root: ".",
  version: Application.spec(:cortex, :vsn)

config :cortex_web, CortexWeb.LinkEndpoint,
  http: [
    port: String.to_integer(
      System.get_env("CORTEX_WEB_LINK_HTTP_PORT") || "4001"
    ),
    transport_options: [socket_opts: [:inet6]],
  ],
  url: [
    scheme: "https",
    host: System.get_env("CORTEX_WEB_LINK_URL_HOST") || "go.expand.live",
    port: 443,
  ],
  server: true

mailgun_api_key =
  System.get_env("CORTEX_MAILGUN_API_KEY") ||
    raise """
    environment variable CORTEX_MAILGUN_API_KEY is missing.
    """

mailgun_domain =
  System.get_env("CORTEX_MAILGUN_DOMAIN") ||
    raise """
    environment variable CORTEX_MAILGUN_DOMAIN is missing.
    """

config :cortex, Cortex.Mailer,
  adapter: Swoosh.Adapters.Mailgun,
  api_key: mailgun_api_key,
  domain: mailgun_domain

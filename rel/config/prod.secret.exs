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
    host: System.get_env("CORTEX_WEB_HOST") || "stats.expand.live",
    port: 80
  ],
  secret_key_base: secret_key_base,
  server: true,
  root: ".",
  version: Application.spec(:cortex, :vsn)

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :cortex_web, CortexWeb.AppEndpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.

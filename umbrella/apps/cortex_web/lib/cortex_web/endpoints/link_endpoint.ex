defmodule CortexWeb.LinkEndpoint do
  use Phoenix.Endpoint, otp_app: :cortex_web

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoints, :link]

  plug Plug.MethodOverride
  plug Plug.Head
  plug CortexWeb.LinkRouter
end

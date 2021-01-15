defmodule CortexWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      CortexWeb.Telemetry,
      # Start the Endpoint (http/https)
      CortexWeb.Endpoint,
      CortexWeb.Endpoints.LinkEndpoint,
      # Start a worker by calling: CortexWeb.Worker.start_link(arg)
      # {CortexWeb.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CortexWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CortexWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

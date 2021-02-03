defmodule CortexWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do

    :ok = :brod.start_client(
      [{'localhost', 9091}],
      :cortex,
      get_brod_client_config()
    )

    children = [
      # Start the Telemetry supervisor
      CortexWeb.Telemetry,
      # Start the Endpoint (http/https)
      CortexWeb.AppEndpoint,
      CortexWeb.LinkEndpoint,
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
    CortexWeb.AppEndpoint.config_change(changed, removed)
    :ok
  end

  def get_brod_client_config() do
    [
      allow_topic_auto_creation: false,
      auto_start_producers: true,
      default_producer_config: [],
      ssl: false,
      sasl: :undefined,
    ]
  end
end

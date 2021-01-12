defmodule Cortex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Cortex.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Cortex.PubSub}
      # Start a worker by calling: Cortex.Worker.start_link(arg)
      # {Cortex.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Cortex.Supervisor)
  end
end

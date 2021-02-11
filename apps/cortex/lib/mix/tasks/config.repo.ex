defmodule Mix.Tasks.Config.Repo do
  use Mix.Task

  @shortdoc "Get Cortex.Repo (database) config"
  def run([]) do
    Application.get_env(:cortex, Cortex.Repo)
    |> Enum.into(%{})
    |> Jason.encode!(pretty: true)
    |> Mix.shell().info()
  end

end

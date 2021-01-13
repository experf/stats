defmodule Mix.Tasks.Config.Get do
  use Mix.Task

  @shortdoc "Get config values"
  def run([app, key]) do
    Application.get_env(
      String.to_atom(app),
      String.to_atom(key)
    )
    |> Enum.into(%{})
    |> Jason.encode!(pretty: true)
    |> Mix.shell().info()
  end

end

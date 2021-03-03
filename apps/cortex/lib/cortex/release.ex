defmodule Cortex.Release do
  @moduledoc """
  Run migrations, etc. in a release.

  Like

  ```bash
  bin/stats eval Cortex.Release.migrate
  ```

  See https://github.com/phoenixframework/phoenix/blob/master/guides/deployment/releases.md#ecto-migrations-and-custom-commands
  """

  @app :cortex

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end

defmodule Subscrape.MixProject do
  use Mix.Project

  def project do
    [
      app: :subscrape,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true}
      {:jason, "~> 1.0"}, # JSON en/decoder
      {:httpoison, "~> 1.8.0"}, # HTTP client
      {:ex_doc, "~> 0.23", only: :dev, runtime: false}, # Docs generation
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
    ]
  end
end

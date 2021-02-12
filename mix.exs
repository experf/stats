defmodule Stats.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      # https://elixirforum.com/t/the-inspect-protocol-has-already-been-consolidated-for-ecto-schema-with-redacted-field/34992/8
      consolidate_protocols: Mix.env() != :dev && Mix.env() != :test,

      # Docs (via `ExDocs`)
      #
      # SEE https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html#module-configuration
      #
      name: "stats",
      source_url: "https://github.com/nrser/stats",
      homepage_url: "https://github.com/nrser/stats",
      docs: [
        main: "readme", # The main page in the docs
        # logo: "path/to/logo.png",
        extras: [
          "README.md"
        ]
      ]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options.
  #
  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps/ folder.
  defp deps do
    []
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  #
  # Aliases listed here are available only for this project
  # and cannot be accessed from applications inside the apps/ folder.
  defp aliases do
    [
      # run `mix setup` in all child apps
      setup: ["cmd mix setup"]
    ]
  end
end

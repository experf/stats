defmodule Mix.Tasks.Project.Get do
  @moduledoc """
  Print a Mix project value
  """

  @shortdoc "Get config values"

  use Mix.Task

  def run(argv) when is_list(argv) do
    {_opts, args, invalid} =
      OptionParser.parse(argv, [
        strict: [output: :string],
        aliases: [o: :output],
      ])

    unless invalid == [], do: raise "Invalid options: #{inspect invalid}"

    value =
      Stats.MixProject.project()
      |> get_in(args |> Enum.map(fn arg -> String.to_atom(arg) end))

    Mix.shell().info(value)
  end
end

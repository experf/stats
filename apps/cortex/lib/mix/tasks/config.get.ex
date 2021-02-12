defmodule Mix.Tasks.Config.Get do
  @moduledoc """
  Print a `Mix.Config` value, as defined in `//config`, respective of the
  `Mix.env/0`.

  Dumps either `JSON` or Elixir's `inspect/2` format (default), controlled by
  an `--output` switch.

  Since many (most?) config values are `Keyword` lists, we understand them as
  `Map` regarding JSON serialization.

  > 📢 Keyword lists with duplicate keys will suffer clobbering when output to
  > JSON.

  Config values are stored by `{atom, atom}` pairs. The task thus expects two
  positional arguments, which are converted to `atom` as follows:

  1.  If the argument string starts with `":"`, that character is removed and
      the remainder of the string becomes the `atom`.

          ":blah" -> :blah

  2.  If the argument string starts with `"Elixir."`, it directly converted into
      an `atom`.

          "Elixir.Cortex.Repo" -> Cortex.Repo = :"Elixir.Cortex.Repo"

  3.  Else "Elixir." is appended before converting to an `atom`.

          "Cortex.Repo" -> Cortex.Repo = :"Elixir.Cortex.Repo"

  ## Examples

  1.  Get an app/key pair with a scalar value — in this case an `atom`:

      ```bash
      $ mix config.get :phoenix :plug_init_mode
      :runtime
      ```

  2.  Print that same value as `JSON`, which converts the `atom` to a `string`:

      ```bash
      $ mix config.get :phoenix :plug_init_mode --output json
      "runtime"
      ```

  3.  Get an app/key pair that has a `Keyword` list value:

      ```bash
      $ mix config.get :subscrape Subscrape
      [cache_root: "/Users/nrser/src/gh/nrser/tmp/cache/subscrape"]
      ```

  4.  When converting to `JSON` we convert `Keyword` lists to objects:

      ```bash
      $ mix config.get :subscrape Subscrape --output json
      {
        "cache_root": "/Users/nrser/src/gh/nrser/tmp/cache/subscrape"
      }
      ```

  5.  Object conversion will clobber data in the odd case that a `Keyword` list
      hopes to preserve duplicate keys:

      ```bash
      $ mix config.get :cortex :weirdness
      [hello: "there", hello: "kitty"]

      $ mix config.get :cortex :weirdness --output json
      {
        "hello": "kitty"
      }
      ```
  """

  @shortdoc "Get config values"

  use Mix.Task

  defp arg_to_atom(arg) when is_binary(arg) do
    cond do
      arg |> String.starts_with?(":") -> arg |> String.slice(1..-1)
      arg |> String.starts_with?("Elixir.") -> arg
      true -> "Elixir.#{arg}"
    end
    |> String.to_atom()
  end

  defp json_encode(list) when is_list(list) do
    if Keyword.keyword?(list) do
      list |> Enum.into(%{}) |> json_encode()
    else
      list |> Jason.encode!(pretty: true)
    end
  end

  defp json_encode(x), do: x |> Jason.encode!(pretty: true)

  def run(argv) when is_list(argv) do
    {opts, args, invalid} =
      OptionParser.parse(argv, [
        strict: [output: :string],
        aliases: [o: :output],
      ])

    unless invalid == [], do: raise "Invalid options: #{inspect invalid}"

    value =
      case args do
        [app, key] -> Application.get_env(arg_to_atom(app), arg_to_atom(key))
        _ -> raise "Expect 2 positional arguments, received #{inspect args}"
      end

    value_s =
      case opts |> Keyword.get(:output, "inspect") do
        "inspect" -> value |> inspect(pretty: true)
        "json" -> value |> json_encode()
        output ->
          raise "Unknown output: #{output}, expected 'inspect' or 'json'"
      end

    Mix.shell().info(value_s)
  end
end

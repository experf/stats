defmodule Cortex.Logging.DevFormatter do
  @pad_size 10
  @pad String.duplicate(" ", @pad_size)
  @levels %{
    error: [:red, "ERROR     ", :reset],
    warn: [:yellow, "WARNING   ", :reset],
    info: [:blue, "INFO      ", :reset],
    debug: [:cyan, "DEBUG     ", :reset]
  }

  @metadata_drop [
    :erl_level,
    :application,
    :domain,
    :gl,
    :mfa,
    :pid,
    :time,
    :request_id
  ]

  # Colors (seems acuate):
  #
  # https://i.stack.imgur.com/KTSQa.png
  #
  @module_color IO.ANSI.color(86)
  @function_color IO.ANSI.color(222)

  @doc """
  Get the working directory to be used when relativizing paths. If
  `$STATS_CLI_CWD` is set in the env, returns that. Otherwise, returns
  `File.cwd!/0`.

  In order to make cmd+click work in iTerm2 needs to be aware that the `stats`
  CLI allows running from any repo subdirectory by `chdir` to `//umbrella`
  before `exec`ing, but iTerm doesn't know about this.

  To allow work-around, `stats` adds a `$STATS_CLI_CWD` env var containing the
  invocation directory, which we look for here, preferring it over the process
  working directory.

  > ❗ This probably doesn't need to be retrieved on every path conversion..?

  """
  def cwd() do
    case System.get_env("STATS_CLI_CWD") do
      nil ->
        case File.cwd() do
          {:ok, cwd} -> cwd
          {:error, _} -> nil
        end

      stats_cwd ->
        stats_cwd
    end
  end

  def rel(path) do
    case cwd() do
      nil -> path
      cwd -> path |> Path.relative_to(cwd)
    end
  end

  def pad(string) when is_binary(string) and byte_size(string) <= 10,
    do: [string, String.duplicate(" ", @pad_size - String.length(string))]

  def pad(string, size)
      when is_binary(string) and
             is_integer(size) and
             size >= byte_size(string) do
    [string, String.duplicate(" ", size - String.length(string))]
  end

  def indent(string, size \\ @pad_size),
    do: string |> String.replace("\n", "\n#{String.duplicate(" ", size)}")

  def format_level(level) when is_atom(level),
    do: @levels[level]

  def format_header([
        {:file, file},
        {:function, function},
        {:line, line},
        {:module, module}
      ]),
      do: [
        format_function(module, function),
        "\n",
        @pad,
        format_location(file, line),
        "\n"
      ]

  def format_header(_),
    do: ["(BAD HEADER)\n"]

  def format_function(module, function),
    do: [
      :faint,
      @module_color,
      module |> Atom.to_string(),
      ".",
      :reset,
      :faint,
      @function_color,
      function,
      :reset
    ]

  def format_location(file, line),
    do: [
      :faint,
      :blue,
      file |> rel(),
      ":",
      Integer.to_string(line),
      :reset
    ]

  def format_message(""), do: []

  def format_message(message) when is_binary(message),
    do: [@pad, indent(message), "\n"]

  def format_metadata([]), do: []

  def format_metadata(metadata) when is_list(metadata) do
    max_key_length =
      metadata
      |> Keyword.keys()
      |> Enum.map(fn key ->
        key |> Atom.to_string() |> String.length()
      end)
      |> Enum.max()

    key_col_width = max_key_length + rem(max_key_length, 2) + 2

    metadata
    |> Enum.map(fn {key, value} ->
      [
        @pad,
        :italic,
        :blue,
        Atom.to_string(key)
        |> pad(key_col_width),
        :reset,
        value
        |> inspect(pretty: true)
        |> indent(@pad_size + key_col_width),
        "\n"
      ]
    end)
  end

  def format(level, message, _timestamp, metadata) do
    {header_kwds, metadata} =
      metadata
      |> Keyword.drop(@metadata_drop)
      |> Keyword.split([:file, :function, :line, :module])

    IO.ANSI.format([
      format_level(level),
      format_header(header_kwds),
      format_message(message),
      format_metadata(metadata),
      "\n"
    ])
  end
end

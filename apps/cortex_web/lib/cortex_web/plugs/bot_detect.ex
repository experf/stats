defmodule CortexWeb.BotDetect do
  require Logger

  import Plug.Conn
  # import Phoenix.Controller

  def get_user_agent(conn) do
    case get_req_header(conn, "user-agent") do
      [] -> nil
      [ua] -> ua
      [ua | _] -> ua
    end
  end

  def crawler?(%{"regex" => regex}, user_agent) do
    user_agent |> String.match?(regex)
  end

  def load_crawler(%{"pattern" => pattern} = crawler) do
    case Regex.compile(pattern) do
      {:ok, regex} ->
        crawler |> Map.put("regex", regex)

      {:error, error} ->
        Logger.error(
          "crawler-user-agents -- Failed to compile pattern",
          pattern: pattern,
          error: error
        )

        :error
    end
  end

  def load_crawlers() do
    with path <-
           Application.app_dir(:cortex_web)
           |> Path.join("priv/crawler-user-agents/crawler-user-agents.json"),
         {:ok, contents} <- File.read(path),
         {:ok, json} <- Jason.decode(contents) do
      json
      |> Enum.map(&load_crawler/1)
      |> Enum.reject(fn crawler -> crawler == :error end)
    end
  end

  def match_crawlers(crawlers, user_agent) do
    crawlers |> Enum.filter(fn crawler -> crawler?(crawler, user_agent) end)
  end

  def assign_crawlers(conn, user_agent) when is_binary(user_agent) do
    crawlers = load_crawlers()

    matches = match_crawlers(crawlers, user_agent)

    case matches do
      [] -> conn
      _ -> conn |> assign(:bots, matches)
    end
  end

  def bot_detect(conn, _opts) do
    case get_user_agent(conn) do
      nil -> conn
      user_agent -> assign_crawlers(conn, user_agent)
    end
  end
end

defmodule CortexWeb.LinkHelpers do
  use Phoenix.HTML

  def github_repo_link(repo_id, opts \\ []) do
    link(
      repo_id,
      [to: "https://github.com/#{repo_id}", target: "_blank"]
      |> Keyword.merge(opts)
    )
  end

  def github_file_link(repo_id, path, opts \\ []) do
    {url_opts, link_opts} =
      [branch: "master", target: "_blank"]
      |> Keyword.merge(opts)
      |> Keyword.split([:branch])

    url = "https://github.com/#{repo_id}/blob/#{url_opts[:branch]}/#{path}"

    link(
      github_file_link_name(repo_id, url),
      [to: url] |> Keyword.merge(link_opts)
    )
  end

  def github_file_link_name(repo_id, path) do
    if Path.extname(path) == ".md" do
      path |> Path.basename(".md") |> humanize()
    else
      "#{repo_id}/#{path}"
    end
  end
end

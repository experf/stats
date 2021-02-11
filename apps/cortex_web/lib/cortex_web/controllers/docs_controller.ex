defmodule CortexWeb.DocsController do
  require Logger

  use CortexWeb, :controller

  @not_found_path Application.app_dir(
    :cortex_web,
    ["priv", "static", "docs", "404.html"]
  )

  @doc ~S"""
  I guess this is needed to properly match the static plugs serving `/docs`.
  """
  def not_found(conn, _) do
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> Plug.Conn.send_file(200, @not_found_path)
  end

  @doc ~S"""
  Basically, add a `/` to the end of the request path and HTTP redirect.

  This allows you to redirect requests for a static directory (eventually) to
  the `index.html` file _in_ that directory — by turning the "bare"
  path `/some-dir` into the "proper" path `/some-dir/`, which will _then_ be
  picked up by `Plug.Static.IndexHtml` and have the `index.html` served.

  Oh bother.

  > ❗❗❗ **_DO NOT_** use this with `Phoenix.Router.forward/4` — it forwards
  > _everything_ the `path` prefix matches (I think), which will cause terrible
  > loop-out mess.
  """
  def redirect_to_dir(conn, _) do
    current_path = conn.request_path
    next_path = conn.request_path <> "/"

    Logger.debug("REDIRECT", current_path: current_path, next_path: next_path)

    redirect(conn, to: next_path)
  end

end

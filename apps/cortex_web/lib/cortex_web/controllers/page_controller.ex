defmodule CortexWeb.PageController do
  require Logger

  use CortexWeb, :controller

  @doc ~S"""
  Where it all starts — the root page.
  """
  def index(conn, _params) do
    render(conn, "index.html", title: "Home", nav: "Stats")
  end

  def splash(conn, _params) do
    render(conn, "splash.html", title: "splash", nav: "Stats")
  end
end

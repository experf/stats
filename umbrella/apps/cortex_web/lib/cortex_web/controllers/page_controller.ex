defmodule CortexWeb.PageController do
  use CortexWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", title: "Home")
  end
end

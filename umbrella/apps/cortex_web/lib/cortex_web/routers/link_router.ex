defmodule CortexWeb.Routers.LinkRouter do
  use CortexWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
  end

  scope "/", CortexWeb do
    pipe_through [:browser]

    get "/", PageController, :index
  end
end

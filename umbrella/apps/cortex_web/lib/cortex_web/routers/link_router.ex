defmodule CortexWeb.LinkRouter do
  use CortexWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
  end

  scope "/", CortexWeb do
    pipe_through [:browser]
    get "/:id", LinkController, :hit
  end
end

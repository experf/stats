defmodule CortexWeb.LinkRouter do
  use CortexWeb, :router

  import CortexWeb.BotDetect

  pipeline :browser do
    plug :accepts, ["html"]
    plug :bot_detect
    plug :put_layout, false
  end

  scope "/", CortexWeb do
    pipe_through [:browser]
    get "/:id", LinkController, :click
  end
end

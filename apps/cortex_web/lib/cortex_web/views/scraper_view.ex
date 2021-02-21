defmodule CortexWeb.ScraperView do
  use CortexWeb, :view

  use Phoenix.HTML

  alias Cortex.Scrapers.Scraper

  def module_options() do
    Scraper.module_values()
    |> Enum.map(fn module ->
      string = Atom.to_string(module)
      name = string |> String.replace(~r/^Elixir\./, "")
      {name, string}
    end)
  end

end

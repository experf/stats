defmodule CortexWeb.LinkView do
  use CortexWeb, :view
  use Phoenix.HTML

  alias Cortex.Trackers.Link

  def click_url(%Link{} = link) do
    CortexWeb.LinkRouter.Helpers.link_url(
      CortexWeb.LinkEndpoint,
      :click,
      link.id
    )
  end

  def click_link(%Link{} = link) do
    url = click_url(link)
    link url, to: url, target: "_blank", class: "external"
  end

  def destination_link(%Link{} = link) do
    link link.destination_url, to: link.destination_url, target: "_blank"
  end

end

defmodule CortexWeb.LinkView do
  use CortexWeb, :view
  use Phoenix.HTML

  alias Cortex.Trackers.Link

  def link_click_url(%Link{} = link) do
    CortexWeb.LinkRouter.Helpers.link_url(
      CortexWeb.LinkEndpoint,
      :click,
      link.id
    )
  end

  def link_click_link(%Link{} = link) do
    url = link_click_url(link)
    link url, to: url, target: "_blank", class: "external"
  end

end

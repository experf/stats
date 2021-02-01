defmodule CortexWeb.NavHelpers do
  use Phoenix.HTML

  def nav_match?(conn, controller, action) do
    Phoenix.Controller.controller_module(conn) == controller &&
      Phoenix.Controller.action_name(conn) == action
  end

  def nav_match?(conn, controller) do
    Phoenix.Controller.controller_module(conn) == controller
  end

  def nav_item(name, opts) do
    {active, link_opts} = case Keyword.split(opts, [:active]) do
      {[], link_opts} -> {false, link_opts}
      {[active: active], link_opts} -> {active, link_opts}
    end
    content_tag :li,
      link(name, link_opts |> Keyword.put(:class, "nav-link")),
      class: if active, do: "nav-item active", else: "nav-item"
  end

  def nav_item(name) do
    content_tag :li, name
  end

end

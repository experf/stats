defmodule CortexWeb.EtcHelpers do
  use Phoenix.HTML
  require Logger

  def maybe(value) when is_nil(value) do
    # content_tag :i, "", class: "bi-dash"
    content_tag :span, "null", class: "is-nil"
  end

  def maybe(value), do: value

end

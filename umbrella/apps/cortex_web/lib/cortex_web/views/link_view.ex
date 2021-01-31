defmodule CortexWeb.LinkView do
  use CortexWeb, :view
  use Phoenix.HTML

  alias Cortex.Trackers.Link
  alias Cortex.OpenGraph
  alias CortexWeb.EtcHelpers

  def click_url(%Link{} = link) do
    CortexWeb.LinkRouter.Helpers.link_url(
      CortexWeb.LinkEndpoint,
      :click,
      link.id
    )
  end

  def click_link(%Link{} = link) do
    url = click_url(link)
    link(url, to: url, target: "_blank", class: "external")
  end

  def destination_link(%Link{} = link) do
    link(link.destination_url, to: link.destination_url, target: "_blank")
  end

  def render_open_graph_meta_tag(property, content) do
    case tag(:meta, property: property, content: content) do
      {:safe, content} -> "#{content}\n"
    end
  end

  def render_open_graph_image(x, acc) when is_nil(x), do: acc

  def render_open_graph_image(list, acc) when is_list(list) do
    list |> Enum.reduce(acc, &render_open_graph_image/2)
  end

  def render_open_graph_image(image, acc) when is_map(image) do
    acc =
      image
      |> Enum.reduce(
        acc,
        fn {key, value}, acc ->
          case key do
            "url" -> acc
            key -> [render_open_graph_meta_tag("og:image:#{key}", value) | acc]
          end
        end
      )

    [render_open_graph_meta_tag("og:image", image["url"]) | acc]
  end

  def render_open_graph_audio(x, acc) when is_nil(x), do: acc

  def render_open_graph_audio(list, acc) when is_list(list) do
    list |> Enum.reduce(acc, &render_open_graph_audio/2)
  end

  def render_open_graph_audio(audio, acc) when is_map(audio) do
    acc =
      audio
      |> Enum.reduce(
        acc,
        fn {key, value}, acc ->
          case key do
            "url" -> acc
            key -> [render_open_graph_meta_tag("og:audio:#{key}", value) | acc]
          end
        end
      )

    [render_open_graph_meta_tag("og:audio", audio.url) | acc]
  end

  def render_open_graph_video(nil = _, acc), do: acc

  def render_open_graph_video(videos, acc) when is_list(videos) do
    videos |> Enum.reduce(acc, &render_open_graph_video/2)
  end

  def render_open_graph_video(video, acc) when is_map(video) do
    acc =
      video
      |> Enum.reduce(
        acc,
        fn {key, value}, acc ->
          case key do
            "url" -> acc
            key -> [render_open_graph_meta_tag("og:video:#{key}", value) | acc]
          end
        end
      )

    [render_open_graph_meta_tag("og:video", video.url) | acc]
  end


  def render_open_graph_metadata(x) when is_nil(x), do: EtcHelpers.maybe(x)

  def render_open_graph_metadata(%Link{} = link) do
    render_open_graph_metadata(link.open_graph_metadata)
  end

  def render_open_graph_metadata(%OpenGraph.Metadata{} = metadata) do
    metadata
    |> Map.from_struct()
    |> Enum.reduce(
      [],
      fn {key, value}, acc ->
        case {key, value} do
          {:__struct__, _} ->
            acc

          {_, nil} -> acc

          {:"og:image", value} ->
            render_open_graph_image(value, acc)

          {:"og:audio", value} ->
            render_open_graph_audio(value, acc)

          {:"og:video", value} ->
            render_open_graph_video(value, acc)

          {key, value} ->
            [
              render_open_graph_meta_tag(
                Atom.to_string(key),
                to_string(value)
              )
              | acc
            ]
        end
      end
    )
    |> (fn acc -> content_tag :pre, acc end).()
  end
end

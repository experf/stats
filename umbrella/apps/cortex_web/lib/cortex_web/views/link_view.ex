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
    tag(:meta, property: property, content: content)
  end

  def render_open_graph_image(acc, nil = _), do: acc

  def render_open_graph_image(acc, %OpenGraph.Metadata.Image{} = image) do
    acc =
      image
      |> Map.keys()
      |> Enum.reduce(
        acc,
        fn acc, key ->
          case key do
            :url -> acc
            key -> render_open_graph_meta_tag("og:image:#{key}", image[key])
          end
        end
      )

    [render_open_graph_meta_tag("og:image", image.url) | acc]
  end

  def render_open_graph_audio(acc, nil = _), do: acc

  def render_open_graph_audio(acc, %OpenGraph.Metadata.Audio{} = audio) do
    acc =
      audio
      |> Map.keys()
      |> Enum.reduce(
        acc,
        fn acc, key ->
          case key do
            :url -> acc
            key -> render_open_graph_meta_tag("og:audio:#{key}", audio[key])
          end
        end
      )

    [render_open_graph_meta_tag("og:audio", audio.url) | acc]
  end

  def render_open_graph_video(acc, nil = _), do: acc

  def render_open_graph_video(acc, %OpenGraph.Metadata.Video{} = video) do
    acc =
      video
      |> Map.keys()
      |> Enum.reduce(
        acc,
        fn acc, key ->
          case key do
            :url -> acc
            key -> render_open_graph_meta_tag("og:video:#{key}", video[key])
          end
        end
      )

    [render_open_graph_meta_tag("og:video", video.url) | acc]
  end

  def render_open_graph_images(acc, images) when is_list(images) do
    images |> Enum.reduce(acc, &render_open_graph_image/2)
  end

  def render_open_graph_metadata(x) when is_nil(x), do: EtcHelpers.maybe(x)

  def render_open_graph_metadata(%Link{} = link) do
    render_open_graph_metadata(link.open_graph_metadata)
  end

  def render_open_graph_metadata(%OpenGraph.Metadata{} = metadata) do
    metadata
    |> Map.keys()
    |> Enum.reduce(
      [],
      fn key, acc ->
        case key do
          :__struct__ ->
            acc

          :"og:image" ->
            render_open_graph_image(acc, metadata |> Map.get(key))

          :"og:audio" ->
            render_open_graph_audio(acc, metadata |> Map.get(key))

          :"og:video" ->
            render_open_graph_video(acc, metadata |> Map.get(key))

          key ->
            [
              render_open_graph_meta_tag(
                Atom.to_string(key),
                to_string(Map.get(metadata, key))
              )
              | acc
            ]
        end
      end
    )
    |> (fn acc -> content_tag :pre, acc end).()
  end
end

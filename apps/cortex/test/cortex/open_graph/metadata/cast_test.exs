defmodule Cortex.OpenGraph.Metadata.CastTest do
  use Cortex.DataCase

  alias Cortex.OpenGraph.Metadata

  describe "Cortex.OpenGraph.Metadata cast functionality" do
    # test "cast_attr/1 with 'empty' values" do
    #   assert [] = Metadata.cast_attr({"k", nil})
    #   assert [] = Metadata.cast_attr({"k", ""}, [])
    #   assert [] = Metadata.cast_attr({"k", []}, [])
    #   assert [] = Metadata.cast_attr({"k", %{}}, [])
    # end

    test "cast_attr/1 with simple values" do
      assert {:"og:title", "Blah"} = Metadata.cast_attr({"og:title", "Blah"})
    end

    test "cast_attr/1 with sub-structure values" do
      {key, images} = Metadata.cast_attr({"og:image", "http://example.com"})

      assert key == :"og:image"
      assert images |> Enum.count() == 1

      image = images |> List.first()
      assert %Metadata.Image{} = image

      assert image.url == "http://example.com"
    end

    test "cast/1 with valid sub-structs" do
      {:ok, meta} =
        Metadata.cast(%{
          "og:title" => "Blah",
          "og:description" => "My site",
          "og:image" => "http://example.com",
          "og:audio" => %{
            "url" => "http://example.com/aud/1.mp3",
            "type" => "audio/mpeg",
          },
          "og:video" => [
            "http://example.com/vid/1.mp4",
            %{
              "url" => "http://example.com/vid/2.mp4",
              "type" => "video/mp4",
              "width" => 4096,
              "height" => 2160,
            },
          ],
        })

      assert %Metadata{} = meta
      assert meta."og:title" == "Blah"
      assert meta."og:description" == "My site"

      images = meta."og:image"
      assert is_list(images)
      assert length(images) == 1

      image = images |> List.first()
      assert %Metadata.Image{} = image
      assert image.url == "http://example.com"

      audios = meta."og:audio"
      assert is_list(audios)
      assert length(audios) == 1

      audio = audios |> List.first()
      assert %Metadata.Audio{} = audio
      assert audio.url == "http://example.com/aud/1.mp3"
      assert audio.type == "audio/mpeg"

      videos = meta."og:video"
      assert is_list(videos)
      assert length(videos) == 2

      [video_1, video_2] = videos

      assert %Metadata.Video{} = video_1
      assert video_1.url == "http://example.com/vid/1.mp4"

      assert %Metadata.Video{} = video_2
      assert video_2.url == "http://example.com/vid/2.mp4"
      assert video_2.type == "video/mp4"
      assert video_2.width == 4096
      assert video_2.height == 2160
    end
  end
end

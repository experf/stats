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

    test "cast/1" do
      {:ok, meta} =
        Metadata.cast(%{
          "og:title" => "Blah",
          "og:description" => "My site",
          "og:image" => "http://example.com"
        })

      assert %Metadata{} = meta

      images = meta."og:image"
      assert is_list(images)
      assert Enum.count(images) == 1

      image = images |> List.first()
      assert %Metadata.Image{} = image
      assert image.url == "http://example.com"
    end
  end
end

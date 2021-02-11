defmodule Cortex.Trackers.Link.OpenGraphMetadataTest do
  use Cortex.DataCase

  import Cortex.AccountsFixtures
  alias Cortex.Trackers

  describe "link.open_graph_metadata" do
    alias Cortex.Trackers.Link
    alias Cortex.OpenGraph

    test "create_link/1 with normalized Open Graph metadata creates a link" do
      attrs = %{
        "destination_url" => "http://stats.test/link/destination_url",
        "open_graph_metadata" => %{
          "og:title" => "What Up",
          "og:image" => [
            %{
              "url" => "http://stats.test/blah",
              "alt" => "BLaH!"
            }
          ],
        }
      }

      assert {:ok, %Link{} = link} = Trackers.create_link(user_fixture(), attrs)

      assert %OpenGraph.Metadata{} = link.open_graph_metadata
      assert link.open_graph_metadata."og:title" == "What Up"
      assert is_list(link.open_graph_metadata."og:image")
      assert %OpenGraph.Metadata.Image{} =
        link.open_graph_metadata."og:image" |> List.first()

      assert link.open_graph_metadata."og:image"
             |> List.first()
             |> Map.get(:url) == "http://stats.test/blah"
    end
  end
end

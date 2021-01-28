defmodule Cortex.TrackersTest do
  use Cortex.DataCase

  import Cortex.AccountsFixtures
  alias Cortex.Trackers

  describe "links" do
    alias Cortex.Trackers.Link

    @valid_attrs %{
      "destination_url" => "http://stats.test/link/destination_url"
    }
    @update_attrs %{}
    @invalid_attrs %{
      "destination_url" => 123
    }

    def link_fixture(attrs \\ %{}) do
      {:ok, link} =
        attrs
        |> Enum.into(@valid_attrs)
        |> (fn attrs -> Trackers.create_link(user_fixture(), attrs) end).()

      link
    end

    test "list_links/0 returns all links" do
      link = link_fixture()
      assert Trackers.list_links() == [link]
    end

    test "get_link!/1 returns the link with given id" do
      link = link_fixture()
      assert Trackers.get_link!(link.id) == link
    end

    test "create_link/1 with valid data creates a link" do
      assert {:ok, %Link{} = _link} =
               Trackers.create_link(user_fixture(), @valid_attrs)
    end

    test "create_link/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Trackers.create_link(user_fixture(), @invalid_attrs)
    end

    test "update_link/2 with valid data updates the link" do
      link = link_fixture()

      assert {:ok, %Link{} = _link} =
               Trackers.update_link(link, user_fixture(), @update_attrs)
    end

    test "update_link/2 with invalid data returns error changeset" do
      link = link_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Trackers.update_link(link, user_fixture(), @invalid_attrs)

      assert link == Trackers.get_link!(link.id)
    end

    test "delete_link/1 deletes the link" do
      link = link_fixture()
      assert {:ok, %Link{}} = Trackers.delete_link(link)
      assert_raise Ecto.NoResultsError, fn -> Trackers.get_link!(link.id) end
    end

    test "change_link/1 returns a link changeset" do
      link = link_fixture()
      assert %Ecto.Changeset{} = Trackers.change_link(link, user_fixture())
    end
  end
end

defmodule Cortex.TrackersTest do
  use Cortex.DataCase

  alias Cortex.Trackers

  describe "links" do
    alias Cortex.Trackers.Link

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def link_fixture(attrs \\ %{}) do
      {:ok, link} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Trackers.create_link()

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
      assert {:ok, %Link{} = link} = Trackers.create_link(@valid_attrs)
    end

    test "create_link/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Trackers.create_link(@invalid_attrs)
    end

    test "update_link/2 with valid data updates the link" do
      link = link_fixture()
      assert {:ok, %Link{} = link} = Trackers.update_link(link, @update_attrs)
    end

    test "update_link/2 with invalid data returns error changeset" do
      link = link_fixture()
      assert {:error, %Ecto.Changeset{}} = Trackers.update_link(link, @invalid_attrs)
      assert link == Trackers.get_link!(link.id)
    end

    test "delete_link/1 deletes the link" do
      link = link_fixture()
      assert {:ok, %Link{}} = Trackers.delete_link(link)
      assert_raise Ecto.NoResultsError, fn -> Trackers.get_link!(link.id) end
    end

    test "change_link/1 returns a link changeset" do
      link = link_fixture()
      assert %Ecto.Changeset{} = Trackers.change_link(link)
    end
  end
end

defmodule Cortex.ScrapersTest do
  use Cortex.DataCase

  alias Cortex.Scrapers

  describe "scrapers" do
    alias Cortex.Scrapers.Scraper

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def scraper_fixture(attrs \\ %{}) do
      {:ok, scraper} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Scrapers.create_scraper()

      scraper
    end

    test "list_scrapers/0 returns all scrapers" do
      scraper = scraper_fixture()
      assert Scrapers.list_scrapers() == [scraper]
    end

    test "get_scraper!/1 returns the scraper with given id" do
      scraper = scraper_fixture()
      assert Scrapers.get_scraper!(scraper.id) == scraper
    end

    test "create_scraper/1 with valid data creates a scraper" do
      assert {:ok, %Scraper{} = scraper} = Scrapers.create_scraper(@valid_attrs)
    end

    test "create_scraper/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Scrapers.create_scraper(@invalid_attrs)
    end

    test "update_scraper/2 with valid data updates the scraper" do
      scraper = scraper_fixture()
      assert {:ok, %Scraper{} = scraper} = Scrapers.update_scraper(scraper, @update_attrs)
    end

    test "update_scraper/2 with invalid data returns error changeset" do
      scraper = scraper_fixture()
      assert {:error, %Ecto.Changeset{}} = Scrapers.update_scraper(scraper, @invalid_attrs)
      assert scraper == Scrapers.get_scraper!(scraper.id)
    end

    test "delete_scraper/1 deletes the scraper" do
      scraper = scraper_fixture()
      assert {:ok, %Scraper{}} = Scrapers.delete_scraper(scraper)
      assert_raise Ecto.NoResultsError, fn -> Scrapers.get_scraper!(scraper.id) end
    end

    test "change_scraper/1 returns a scraper changeset" do
      scraper = scraper_fixture()
      assert %Ecto.Changeset{} = Scrapers.change_scraper(scraper)
    end
  end
end

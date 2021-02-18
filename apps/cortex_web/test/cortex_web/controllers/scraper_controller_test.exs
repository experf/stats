defmodule CortexWeb.ScraperControllerTest do
  use CortexWeb.ConnCase

  alias Cortex.Scrapers

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  def fixture(:scraper) do
    {:ok, scraper} = Scrapers.create_scraper(@create_attrs)
    scraper
  end

  describe "index" do
    test "lists all scrapers", %{conn: conn} do
      conn = get(conn, Routes.scraper_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Scrapers"
    end
  end

  describe "new scraper" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.scraper_path(conn, :new))
      assert html_response(conn, 200) =~ "New Scraper"
    end
  end

  describe "create scraper" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.scraper_path(conn, :create), scraper: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.scraper_path(conn, :show, id)

      conn = get(conn, Routes.scraper_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Scraper"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.scraper_path(conn, :create), scraper: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Scraper"
    end
  end

  describe "edit scraper" do
    setup [:create_scraper]

    test "renders form for editing chosen scraper", %{conn: conn, scraper: scraper} do
      conn = get(conn, Routes.scraper_path(conn, :edit, scraper))
      assert html_response(conn, 200) =~ "Edit Scraper"
    end
  end

  describe "update scraper" do
    setup [:create_scraper]

    test "redirects when data is valid", %{conn: conn, scraper: scraper} do
      conn = put(conn, Routes.scraper_path(conn, :update, scraper), scraper: @update_attrs)
      assert redirected_to(conn) == Routes.scraper_path(conn, :show, scraper)

      conn = get(conn, Routes.scraper_path(conn, :show, scraper))
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, scraper: scraper} do
      conn = put(conn, Routes.scraper_path(conn, :update, scraper), scraper: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Scraper"
    end
  end

  describe "delete scraper" do
    setup [:create_scraper]

    test "deletes chosen scraper", %{conn: conn, scraper: scraper} do
      conn = delete(conn, Routes.scraper_path(conn, :delete, scraper))
      assert redirected_to(conn) == Routes.scraper_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.scraper_path(conn, :show, scraper))
      end
    end
  end

  defp create_scraper(_) do
    scraper = fixture(:scraper)
    %{scraper: scraper}
  end
end

defmodule CortexWeb.LinkController do
  use CortexWeb, :controller

  alias Cortex.Trackers
  alias Cortex.Trackers.Link

  def index(conn, _params) do
    links = Trackers.list_links()
    render(conn, "index.html", links: links, title: "Links", nav: "Links")
  end

  def new(conn, _params) do
    changeset = Trackers.change_link(%Link{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"link" => link_params}) do
    case Trackers.create_link(conn.assigns.current_user, link_params) do
      {:ok, link} ->
        conn
        |> put_flash(:info, "Link created successfully.")
        |> redirect(to: Routes.link_path(conn, :show, link))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    link = Trackers.get_link!(id)
    render(conn, "show.html", link: link)
  end

  def edit(conn, %{"id" => id}) do
    link = Trackers.get_link!(id)
    changeset = Trackers.change_link(link)
    render(conn, "edit.html", link: link, changeset: changeset)
  end

  def update(conn, %{"id" => id, "link" => link_params}) do
    link = Trackers.get_link!(id)

    case Trackers.update_link(link, link_params) do
      {:ok, link} ->
        conn
        |> put_flash(:info, "Link updated successfully.")
        |> redirect(to: Routes.link_path(conn, :show, link))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", link: link, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    link = Trackers.get_link!(id)
    {:ok, _link} = Trackers.delete_link(link)

    conn
    |> put_flash(:info, "Link deleted successfully.")
    |> redirect(to: Routes.link_path(conn, :index))
  end

  def follow(conn, %{"id" => id}) do
    link = Trackers.get_link!(id)
    conn |> redirect(external: link.destination_url)
  end
end

defmodule CortexWeb.LinkController do
  use CortexWeb, :controller

  alias Cortex.Trackers
  alias Cortex.Trackers.Link
  alias Cortex.Events

  def index(conn, _params) do
    links = Trackers.list_links()
    render(conn, "index.html", links: links, title: "Links", nav: "Links")
  end

  def new(conn, _params) do
    changeset = Trackers.change_link(%Link{}, conn.assigns.current_user)
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"link" => link_params}) do
    case Trackers.create_link(
      conn.assigns.current_user,
      link_params
    ) do
      {:ok, link} ->
        conn
        |> put_flash(:info, "Link created successfully.")
        |> redirect(to: Routes.link_path(conn, :show, link))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    link = Trackers.get_link!(id, preload: true)
    render(conn, "show.html", link: link)
  end

  def edit(conn, %{"id" => id}) do
    link = Trackers.get_link!(id)
    changeset = Trackers.change_link(link, conn.assigns.current_user)
    render(conn, "edit.html", link: link, changeset: changeset)
  end

  def update(conn, %{"id" => id, "link" => link_params}) do
    link = Trackers.get_link!(id)

    case Trackers.update_link(link, conn.assigns.current_user, link_params) do
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

  def click(conn, %{"id" => id}) do
    link = Trackers.get_link!(id)

    Events.produce(%{
      app: "cortex",
      type: "link.click",
      link: %{
        id: link.id,
      },
      dest_url: link.destination_url,
      src_url: Phoenix.Controller.current_url(conn),
      # https://hexdocs.pm/plug/Plug.Conn.html
      request: %{
        host: conn.host,
        path: conn.request_path,
        ip:
          conn.remote_ip
          |> Tuple.to_list
          |> Enum.map(&Integer.to_string/1)
          |> Enum.join("."),
        query: conn.query_string,
        # https://en.wikipedia.org/wiki/List_of_HTTP_header_fields
        referer: get_req_header(conn, "referer"),
        user_agent: get_req_header(conn, "user-agent"),
      },
    })

    conn |> redirect(external: link.destination_url)
  end
end

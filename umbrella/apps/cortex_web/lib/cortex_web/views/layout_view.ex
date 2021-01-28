defmodule CortexWeb.LayoutView do
  use CortexWeb, :view

  # https://hexdocs.pm/phoenix/Phoenix.Naming.html
  alias Phoenix.Naming

  # Import convenience functions from controllers
  import Phoenix.Controller,
    only: [
      get_flash: 1,
      get_flash: 2,
      view_module: 1,
      view_template: 1
  ]

  # SEE https://github.com/phoenixframework/phoenix/blob/e05af0ad5527c9a192de122f3e43d7ed4c7a4c9f/lib/phoenix/controller.ex#L1454
  def to_s(binary) when is_binary(binary), do: binary
  def to_s(atom) when is_atom(atom), do: Atom.to_string(atom)

  def has_flash?(conn, key) do
    get_flash(conn) |> Map.has_key?(to_s(key))
  end

  def get_param(conn, key) do
    conn.query_params |> Map.get(to_s(key))
  end

  def opt?(conn, key, value) do
    get_param(conn, key) == value
  end

  def view_name(conn) do
    conn
    |> view_module()
    |> Naming.resource_name("View")
    |> Naming.underscore()
  end

  def template_name(conn) do
    conn
    |> view_template()
    |> Path.basename(".html")
  end

  def view_classes(conn) do
    view_name(conn) <> " " <> template_name(conn)
  end

end

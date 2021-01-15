defmodule Cortex.Trackers do
  @moduledoc """
  The Trackers context.
  """

  import Ecto.Query, warn: false
  alias Cortex.Repo

  alias Cortex.Trackers.Link
  alias Cortex.Accounts.User

  @doc """
  Returns the list of links.

  ## Examples

      iex> list_links()
      [%Link{}, ...]

  """
  def list_links do
    Repo.all(Link)
  end

  @doc """
  Gets a single link.

  Raises `Ecto.NoResultsError` if the Link does not exist.

  ## Examples

      iex> get_link!(123)
      %Link{}

      iex> get_link!(456)
      ** (Ecto.NoResultsError)

  """

  @doc """
  Creates a link.

  ## Examples

      iex> create_link(%{field: value})
      {:ok, %Link{}}

      iex> create_link(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def get_link!(id), do: Repo.get!(Link, id)

  def create_link(user, attrs \\ %{})

  # def create_link(%User{} = user, %{id: id} = attrs) when is_binary(id) do
  #   %Link{
  #     inserted_by_id: user.id,
  #     updated_by_id: user.id
  #   }
  #   |> Link.create_changeset(attrs)
  #   |> Repo.insert()
  # end

  def create_link(%User{} = user, attrs) do
    %Link{}
    |> Link.create_changeset(user, attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a link.

  ## Examples

      iex> update_link(link, %{field: new_value})
      {:ok, %Link{}}

      iex> update_link(link, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_link(%Link{} = link, attrs) do
    link
    |> Link.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a link.

  ## Examples

      iex> delete_link(link)
      {:ok, %Link{}}

      iex> delete_link(link)
      {:error, %Ecto.Changeset{}}

  """
  def delete_link(%Link{} = link) do
    Repo.delete(link)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking link changes.

  ## Examples

      iex> change_link(link)
      %Ecto.Changeset{data: %Link{}}

  """
  def change_link(%Link{} = link, attrs \\ %{}) do
    Link.changeset(link, attrs)
  end
end

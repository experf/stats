defmodule Cortex.Types.JSONMap do
  @moduledoc """
  Attempt to provide a generic Ecto type for JSON data validated by a JSON
  schema.
  """

  require Logger

  # https://hexdocs.pm/ecto/Ecto.Type.html
  use Ecto.Type

  @doc """
  Gets the underlying Ecto type to use for storage. This can of course be one of
  [Ecto base types][], but it can also be another type that the adapter
  understands:

  <https://hexdocs.pm/ecto/Ecto.Type.html#c:type/0>

  """
  @impl true
  def type(), do: :map

  @impl true
  def cast(json) when is_binary(json) do
    case json |> Jason.decode() do
      {:error, %Jason.DecodeError{} = error} -> {:error, [decode: error]}
      {:ok, _} = result -> result
    end
  end

  def cast(map) when is_map(map), do: {:ok, map}

  def cast(value) do
    Logger.error("Bad cast value", value: value)
    :error
  end

  @impl true
  def load(map) when is_map(map), do: {:ok, map}

  def load(value) do
    Logger.error("Bad load value", value: value)
    :error
  end

  @impl true
  def dump(data) when is_map(data), do: {:ok, data}

  def dump(value) do
    Logger.error("Bad dump value", value: value)
    :error
  end

end

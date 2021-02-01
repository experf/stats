defmodule Cortex.Types.JSONSchemaMap do
  @moduledoc """
  Attempt to provide a generic Ecto type for JSON data validated by a JSON
  schema.
  """

  require Logger

  # https://hexdocs.pm/ecto/Ecto.ParameterizedType.html#content
  use Ecto.ParameterizedType

  defmacro is_empty(value) do
    quote do
      is_nil(unquote(value)) or
        unquote(value) == "" or
        unquote(value) == [] or
        unquote(value) == %{}
    end
  end
  @doc """
  Convert the options specified in the field macro into parameters to be used in
  other callbacks.
  """
  def init(opts) do
    json_schema =
      case opts[:json_schema] do
        # %JsonXema{} = json_schema -> json_schema

        json when is_binary(json) ->
          json |> Jason.decode!(strings: :copy) |> JsonXema.new()

        map when is_map(map) ->
          map |> JsonXema.new()
      end

    opts |> Keyword.put(:json_schema, json_schema) |> Enum.into(%{})
  end

  @doc """
  Gets the underlying Ecto type to use for storage. This can of course be one of
  [Ecto base types][], but it can also be another type that the adapter
  understands:

  <https://hexdocs.pm/ecto/Ecto.Type.html#c:type/0>

  We'd like a type that directly maps to Postgres' `jsonb` type, but after
  poking around [postgrex][] a minute I'm not sure if there is one built-in.

  For now, it's the `:map` base type.

  [Ecto base types]: https://hexdocs.pm/ecto/Ecto.Type.html#c:type/0
  [postgrex]: https://hexdocs.pm/postgrex/

  """
  def type(_), do: :map

  def cast(data, %{json_schema: json_schema}) when is_map(data) do
    case JsonXema.validate(json_schema, data) do
      {:error, %JsonXema.ValidationError{} = error} ->
        {:error, [validation: error]}

      :ok ->
        {:ok, data}
    end
  end

  def cast(json, params) when is_binary(json) do
    case json |> Jason.decode() do
      {:error, %Jason.DecodeError{} = error} ->
        {:error, [decode: error]}

      {:ok, data} ->
        cast(data, params)
    end
  end

  def cast(_, _), do: :error

  def load(data, _loader, %{json_schema: json_schema}) do
    case JsonXema.validate(json_schema, data) do
      {:error, %JsonXema.ValidationError{} = error} ->
        {:error, [validation: error]}

      :ok ->
        {:ok, data}
    end
  end

  def dump(data, _dumper, _params) do
    {:ok, data}
  end

  def equal?(a, b, _params) do
    a == b
  end
end

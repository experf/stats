defmodule Cortex.OpenGraph.Metadata do
  use Ecto.Type
  require Logger

  alias Cortex.JSONSchema
  alias Cortex.OpenGraph.Metadata.{Image, Audio, Video}

  @schema Application.get_env(:cortex, __MODULE__)[:schema_json]
          |> Jason.decode!(strings: :copy)
          |> JsonXema.new()

  @sub_structs %{
    :"og:image" => Image,
    :"og:audio" => Audio,
    :"og:video" => Video
  }

  @sub_module_keys Map.keys(@sub_structs)
  @sub_module_key_strings Enum.map(@sub_module_keys, &Atom.to_string/1)

  # https://hexdocs.pm/ecto/Ecto.Type.html

  defstruct [
    :"og:title",
    :"og:type",
    :"og:url",
    :"og:description",
    :"og:determiner",
    :"og:locale",
    :"og:site_name",
    :"og:image",
    :"og:audio",
    :"og:video"
  ]

  def type, do: :map

  defp cast_reduce({_, ext_value}, kwds) when is_nil(ext_value), do: kwds

  defp cast_reduce({ext_key, ext_value}, kwds)
       when ext_key in @sub_module_key_strings do
    key = String.to_existing_atom(ext_key)
    struct = @sub_structs[key]

    value =
      case ext_value do
        list when is_list(list) ->
          list |> Enum.map(&struct.cast!/1)

        any ->
          [struct.cast!(any)]
      end

    [{key, value} | kwds]
  end

  defp cast_reduce({ext_key, ext_value}, kwds) do
    [{String.to_existing_atom(ext_key), ext_value} | kwds]
  end

  @spec cast(any) :: :error | {:error, keyword()} | {:ok, %__MODULE__{}}

  def cast(attrs) when is_map(attrs) do
    case JsonXema.validate(@schema, attrs) do
      {:error, %JsonXema.ValidationError{} = error} ->
        {:error, [schema_validation: error]}

      :ok ->
        {:ok, struct!(__MODULE__, attrs |> Enum.reduce([], &cast_reduce/2))}
    end
  end

  def cast("" = _), do: {:ok, %__MODULE__{}}

  def cast(json) when is_binary(json) do
    case json do
      "" -> {:ok, %__MODULE__{}}
      _ -> json |> Jason.decode!() |> cast()
    end
  end

  def cast(_), do: :error

  defp load_reduce({db_key, db_value}, kwds)
       when db_key in @sub_module_key_strings do
    key = String.to_existing_atom(db_key)
    struct = @sub_structs[key]
    value = db_value |> Enum.map(&struct.load!/1)
    [{key, value} | kwds]
  end

  defp load_reduce({db_key, db_value}, kwds) when is_binary(db_key) do
    [{String.to_existing_atom(db_key), db_value} | kwds]
  end

  def load(db_data) when is_map(db_data) do
    {:ok, struct!(__MODULE__, db_data |> Enum.reduce([], &load_reduce/2))}
  end

  defp dump_reduce({_, value}, kwds) when is_nil(value), do: kwds

  defp dump_reduce({key, value}, kwds) when key in @sub_module_keys do
    struct = @sub_structs[key]
    [{key, value |> Enum.map(&struct.dump!/1)} | kwds]
  end

  defp dump_reduce({key, value}, kwds), do: [{key, value} | kwds]

  def dump(%__MODULE__{} = metadata) do
    {
      :ok,
      metadata
      |> Map.from_struct()
      |> Enum.reduce([], &dump_reduce/2)
      |> Enum.into(%{})
    }
  end

  def dump(_), do: :error

  defimpl Jason.Encoder do
    def encode(metadata, opts) do
      case metadata
           |> Map.from_struct()
           |> Enum.reject(&JSONSchema.empty_pair?/1) do
        [] ->
          Jason.encode(nil, opts)

        list ->
          list
          |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
          |> Enum.into(%{})
          |> Jason.Encode.map(opts)
      end
    end
  end
end

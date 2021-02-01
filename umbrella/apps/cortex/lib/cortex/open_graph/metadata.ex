defmodule Cortex.OpenGraph.Metadata do
  use Ecto.Type
  require Logger
  import Cortex.JSONSchema

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

  @sub_struct_keys Map.keys(@sub_structs)

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

  # Functions
  # ============================================================================

  def type, do: :map

  def validate(value) do
    case JsonXema.validate(@schema, value) do
      {:error, %JsonXema.ValidationError{} = error} ->
        {:error, [schema_validation: error]}

      :ok -> :ok
    end
  end

  # Casting -- Converting External Input to Runtime Structure
  # ----------------------------------------------------------------------------

  def cast_attr({ext_key, ext_value}) when is_binary(ext_key),
    do: cast_attr({String.to_existing_atom(ext_key), ext_value})

  def cast_attr({key, ext_value})
      when is_atom(key) and key in @sub_struct_keys do
    struct = @sub_structs[key]

    value =
      case ext_value do
        list when is_list(list) ->
          list |> Enum.map(&struct.cast!/1)

        any ->
          [struct.cast!(any)]
      end

    {key, value}
  end

  def cast_attr({key, _} = attr) when is_atom(key),
    do: attr

  @spec cast(any) :: :error | {:error, keyword()} | {:ok, %__MODULE__{}}

  def cast(attrs) when is_map(attrs) do
    case validate(attrs) do
      {:error, _} = error ->
        error

      :ok ->
        kwds =
          for {_, value} = attr when not is_empty(value) <- attrs,
              do: cast_attr(attr)

        {:ok, struct!(__MODULE__, kwds)}
    end
  end

  def cast(json) when json == "",
    do: {:ok, %__MODULE__{}}

  def cast(json) when is_binary(json) do
    case json do
      "" -> {:ok, %__MODULE__{}}
      _ -> json |> Jason.decode!() |> cast()
    end
  end

  def cast(_),
    do: :error

  # Loading -- Converting Ecto Types to Runtime Structure
  # --------------------------------------------------------------------------

  def load_attr({ecto_key, ecto_value}) when is_binary(ecto_key),
    do: cast_attr({ecto_key |> String.to_existing_atom(), ecto_value})

  def load_attr({key, ecto_value})
      when key in @sub_struct_keys do
    struct = @sub_structs[key]
    {key, ecto_value |> Enum.map(&struct.load!/1)}
  end

  def load_attr({key, _} = attr) when is_atom(key),
    do: attr

  def load!(ecto_data) when is_map(ecto_data) do
    __MODULE__ |> struct!(for attr <- ecto_data, do: load_attr(attr))
  end

  def load(ecto_data) when is_map(ecto_data),
    do: {:ok, ecto_data |> load!()}

  # Dumping -- Converting Runtime Structure to Ecto Types
  # --------------------------------------------------------------------------

  def dump_attr({key, value}) when key in @sub_struct_keys do
    struct = @sub_structs[key]
    {key, value |> Enum.map(&struct.dump!/1)}
  end

  def dump_attr(kv), do: kv

  def dump!(%__MODULE__{} = struct) do
    for(
      {_, v} = kv when not is_empty(v) <- struct |> Map.from_struct(),
      do: dump_attr(kv)
    )
    |> Enum.into(%{})
  end

  def dump(%__MODULE__{} = struct),
    do: {:ok, struct |> dump!()}

  def dump(_), do: :error

  # JSON Serialization
  # --------------------------------------------------------------------------

  defimpl Jason.Encoder, for: [__MODULE__, Image, Audio, Video] do
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

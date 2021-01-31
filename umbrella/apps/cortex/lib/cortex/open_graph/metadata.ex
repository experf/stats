defmodule Cortex.OpenGraph.Metadata do
  use Ecto.Type
  require Logger

  alias Cortex.JSONSchema
  alias Cortex.OpenGraph.Metadata
  alias Cortex.OpenGraph.Metadata.{Image, Audio, Video}

  @schema Application.get_env(:cortex, __MODULE__)[:schema_json]
          |> Jason.decode!(strings: :copy)
          |> JsonXema.new()

  # https://hexdocs.pm/ecto/Ecto.Type.html

  # @derive Jason.Encoder
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

  def cast_sub_struct(struct, external_data) when is_map(external_data) do
    data =
      for {key_s, value} <- JSONSchema.filter(external_data) do
        {String.to_existing_atom(key_s), value}
      end

    struct!(struct, data)
  end

  def cast_sub_struct(struct, external_data) when is_binary(external_data) do
    struct!(struct, %{url: external_data})
  end

  def cast_sub_list(struct, external_data) when is_list(external_data) do
    external_data |> Enum.map(&cast_sub_struct(struct, &1))
  end

  def cast_sub_list(struct, external_data)
      when is_map(external_data) or is_binary(external_data) do
    [cast_sub_struct(struct, external_data)]
  end

  def cast(external_data) when is_map(external_data) do
    with  :ok <- JsonXema.validate(@schema, external_data),
          data <- (for {ext_key, ext_value} <- JSONSchema.filter(external_data) do
            key = String.to_existing_atom(ext_key)

            value =
              case key do
                :"og:image" -> cast_sub_list(Image, ext_value)
                :"og:audio" -> cast_sub_list(Audio, ext_value)
                :"og:video" -> cast_sub_list(Video, ext_value)
                _ -> ext_value
              end

            {key, value}
          end),
      do: {:ok, struct!(__MODULE__, data)}
  end

  def cast("" = _), do: %__MODULE__{}

  def cast(external_data) when is_binary(external_data) do
    case external_data do
      "" -> %__MODULE__{}
      _ -> external_data |> Jason.decode!() |> cast()
    end
  end

  def cast(_), do: :error

  def load(db_data) when is_map(db_data) do
    data =
      for {key, val} <- db_data do
        {String.to_existing_atom(key), val}
      end

    {:ok, struct!(__MODULE__, data)}
  end

  def dump(%Metadata{} = metadata) do
    {
      :ok,
      metadata
      |> Map.from_struct()
      |> Enum.reject(&JSONSchema.empty_pair?/1)
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

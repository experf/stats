defmodule Cortex.OpenGraph.Metadata do
  use Ecto.Type
  require Logger

  alias Cortex.OpenGraph.Metadata
  alias Cortex.OpenGraph.Metadata.{Image, Audio, Video}

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

  @spec empty_value?(any) :: boolean
  def empty_value?(x) when is_nil(x), do: true
  def empty_value?(x) when is_binary(x), do: String.length(x) == 0
  def empty_value?(x) when is_list(x) or is_map(x), do: Enum.count(x) == 0
  def empty_value?(_), do: false

  def empty_pair?({_, value}), do: empty_value?(value)

  def filter(external_data) when is_map(external_data) do
    external_data |> Map.to_list() |> Enum.reject(&empty_pair?/1)
  end

  def cast_sub_struct(struct, external_data) when is_map(external_data) do
    data =
      for {key_s, value} <- filter(external_data) do
        {String.to_existing_atom(key_s), value}
      end

    struct!(struct, data)
  end

  def cast_sub_struct(struct, external_data) when is_binary(external_data) do
    struct!(struct, %{url: external_data})
  end

  def cast_sub_list(struct, external_data) when is_list(external_data) do
    external_data |> Enum.map(&(cast_sub_struct(struct, &1)))
  end

  def cast_sub_list(struct, external_data)
      when is_map(external_data) or is_binary(external_data) do
    [cast_sub_struct(struct, external_data)]
  end

  def cast(external_data) when is_map(external_data) do
    data =
      for {key_s, value} <- filter(external_data) do
        key = String.to_existing_atom(key_s)
        value =
          case key do
            :"og:image"-> cast_sub_list(Image, value)
            :"og:audio"-> cast_sub_list(Audio, value)
            :"og:video"-> cast_sub_list(Video, value)
            key -> key
          end

        {key, value}
      end

    {:ok, struct!(Metadata, data)}
  end

  def cast("" = _), do: %Metadata{}

  def cast(external_data) when is_binary(external_data) do
    case external_data do
      "" -> %Metadata{}
      _ -> external_data |> Jason.decode!() |> cast()
    end
  end

  def cast(_), do: :error

  def load(db_data) when is_map(db_data) do
    data =
      for {key, val} <- db_data do
        {String.to_existing_atom(key), val}
      end

    {:ok, struct!(Metadata, data)}
  end

  def dump(%Metadata{} = metadata) do
    {
      :ok,
      metadata
      |> Map.from_struct()
      |> Enum.reject(&empty_pair?/1)
      |> Enum.into(%{})
    }
  end

  def dump(_), do: :error

  defimpl Jason.Encoder do
    def encode(metadata, opts) do
      case metadata
           |> Map.from_struct()
           |> Enum.reject(&Metadata.empty_pair?/1) do
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

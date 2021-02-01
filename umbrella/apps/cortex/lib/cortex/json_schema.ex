defmodule Cortex.JSONSchema do
  defmacro is_empty(ext_value) do
    quote do
      is_nil(unquote(ext_value)) or
        unquote(ext_value) == "" or
        unquote(ext_value) == [] or
        unquote(ext_value) == %{}
    end
  end

  defmacro __using__(_) do

    quote do
      import Cortex.JSONSchema

      unless Module.has_attribute?(__MODULE__, :sub_structs) do
        @sub_structs %{}
      end

      @sub_struct_keys Map.keys(@sub_structs)

      if Module.has_attribute?(__MODULE__, :schema) do
        def validate(value) do
          case JsonXema.validate(@schema, value) do
            {:error, %JsonXema.ValidationError{} = error} ->
              {:error, [schema_validation: error]}

            :ok -> :ok
          end
        end
      end

      # Casting -- Converting External Input to Runtime Structure
      # ----------------------------------------------------------------------------

      def cast_attr({ext_key, ext_value}) when is_binary(ext_key),
        do: cast_attr({String.to_existing_atom(ext_key), ext_value})

      unless @sub_struct_keys == [] do
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
      end

      def cast_attr({key, _} = attr) when is_atom(key),
        do: attr

      if Module.has_attribute?(__MODULE__, :schema) do
        def cast!(attrs) when is_map(attrs) do
          case validate(attrs) do
            {:error, _} = error ->
              error

            :ok ->
              kwds =
                for {_, value} = attr when not is_empty(value) <- attrs,
                    do: cast_attr(attr)

              struct!(__MODULE__, kwds)
          end
        end
      else
        def cast!(attrs) when is_map(attrs) do
          kwds =
            for {_, value} = attr when not is_empty(value) <- attrs,
                do: cast_attr(attr)

          struct!(__MODULE__, kwds)
        end
      end

      def cast(attrs) when is_map(attrs),
        do: {:ok, attrs |> cast!()}

      def cast(json) when json == "",
        do: {:ok, %__MODULE__{}}

      def cast(json) when is_binary(json),
        do: {:ok, json |> Jason.decode!() |> cast!()}

      def cast(_),
        do: :error

      # Loading -- Converting Ecto Types to Runtime Structure
      # --------------------------------------------------------------------------

      def load_attr({ecto_key, ecto_value}) when is_binary(ecto_key),
        do: cast_attr({ecto_key |> String.to_existing_atom(), ecto_value})

      unless @sub_struct_keys == [] do
        def load_attr({key, ecto_value})
            when key in @sub_struct_keys do
          struct = @sub_structs[key]
          {key, ecto_value |> Enum.map(&struct.load!/1)}
        end
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

      unless @sub_struct_keys == [] do
        def dump_attr({key, value}) when key in @sub_struct_keys do
          struct = @sub_structs[key]
          {key, value |> Enum.map(&struct.dump!/1)}
        end
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

      defimpl Jason.Encoder do
        def encode(struct, opts) do
          case struct
               |> Map.from_struct()
               |> Enum.reject(&Cortex.JSONSchema.empty_pair?/1) do
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
  end

  @spec empty_value?(any) :: boolean
  def empty_value?(x) when is_nil(x), do: true
  def empty_value?(x) when is_binary(x), do: String.length(x) == 0
  def empty_value?(x) when is_list(x) or is_map(x), do: Enum.count(x) == 0
  def empty_value?(_), do: false

  @spec empty_pair?({any, any}) :: boolean
  def empty_pair?({_, value}), do: empty_value?(value)
end

defmodule Cortex.JSONSchema do
  defmacro is_empty(ext_value) do
    quote do
      is_nil(unquote(ext_value)) or
        unquote(ext_value) == "" or
        unquote(ext_value) == [] or
        unquote(ext_value) == %{}
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

defmodule Subscrape.Helpers do
  @moduledoc ~S"""
  TODO Document Subscrape.Helpers module...
  """

  def after?({:error, _}, _), do: false

  def after?({:ok, actual}, criteria), do: after?(actual, criteria)

  def after?(actual, criteria) do
    case DateTime.compare(actual, criteria) do
      :gt -> true
      _ -> false
    end
  end

  def check_ok!(message, module, function_name, args)
      when is_binary(message) do
    case apply(module, function_name, args) do
      {:ok, result} -> result
      {:error, error} -> raise Subscrape.Error, message: message, reason: error
    end
  end

  def check_ok!({format, terms}, module, function_name, args)
      when is_binary(format) and is_list(terms) do
    case apply(module, function_name, args) do
      {:ok, result} ->
        result

      {:error, error} ->
        data = terms |> Enum.map(&(to_string &1))
        message = :io_lib.format(format, data) |> to_string()
        raise Subscrape.Error, message: message, reason: error
    end
  end
end

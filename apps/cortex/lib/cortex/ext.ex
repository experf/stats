defmodule Cortex.Ext do
  @moduledoc ~S"""
  TODO Document Ext module...
  """

  defmodule DateTime do

    def from_iso8601!(string, calendar \\ Calendar.ISO) do
      case :"Elixir.DateTime".from_iso8601(string, calendar) do
        {:ok, datetime, _offset} ->
          datetime

        {:error, atom} ->
          raise ArgumentError,
            message: "Unable to parse ISO 8601 date: #{atom}"
      end
    end
  end
end

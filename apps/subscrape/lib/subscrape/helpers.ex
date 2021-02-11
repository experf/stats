defmodule Subscrape.Helpers do
  @moduledoc ~S"""
  Assorted shit (that may or may not help).
  """

  defmacro is_status_class(value, class) do
    quote do
      is_integer(unquote(value)) and
      unquote(value) >= (div(unquote(class), 100)) * 100 and
      unquote(value) < (div(unquote(class), 100) + 1) * 100
    end
  end

end # defmodule Subscrape.Helpers

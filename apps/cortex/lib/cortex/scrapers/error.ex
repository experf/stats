defmodule Cortex.Scrapers.Error do
  defexception message: nil, cause: nil
  @type t :: %__MODULE__{message: binary, cause: any}

  def message(%__MODULE__{message: nil, cause: nil}),
    do: "Unknown error"

  def message(%__MODULE__{message: message, cause: nil}),
    do: message

  def message(%__MODULE__{message: message, cause: cause}),
    do: message <> " -- " <> inspect(cause)

end

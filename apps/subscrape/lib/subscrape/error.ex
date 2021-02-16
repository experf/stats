defmodule Subscrape.Error do
  defexception message: nil, reason: nil
  @type t :: %__MODULE__{message: binary, reason: any}

  def message(%__MODULE__{message: nil, reason: nil}),
    do: "Unknown error"

  def message(%__MODULE__{message: message, reason: nil}),
    do: message

  def message(%__MODULE__{message: message, reason: reason})
      when is_binary(reason),
    do: message <> " -- " <> reason

  def message(%__MODULE__{message: message, reason: %{message: reason}})
      when is_binary(reason),
    do: message <> " -- " <> reason

  def message(%__MODULE__{message: message, reason: reason}),
    do: message <> " -- " <> inspect(reason)

end

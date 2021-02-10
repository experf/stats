defmodule Subscrape.Endpoint do
  @moduledoc ~S"""
  TODO Document Subscrape.Endpoint module...
  """

  @enforce_keys [:format]
  defstruct [
    :format,
    :extract_key,
    :page_key
  ]

end # defmodule Subscrape.Endpoint

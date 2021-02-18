defmodule Subscrape.Endpoint do
  @moduledoc ~S"""
  Useful structure for defining Substack's API endpoints.
  """

  @type t :: %__MODULE__{
    format: binary,
    extract_key: nil | binary,
    page_arg: nil | binary,
  }

  @doc ~S"""
  A small structure of information about a Substack API endpoint.

  -   `:format` — `EEx` template string that produces the HTTP path.

  -   `:extract_key` — Optional JSON object key (string) that holds the actual
      records in responses.

      For instance, `/api/v1/subscribers` responds like:

      ```json
      {"subscribers": [subscriber, subscriber, ...]}
      ```

      Setting `extract_key: "subscribers"` allows `Subscrape.HTTP.collect/4` to
      find the right data when paginating.

  -   `:page_arg` — Argument name to use for the last records from the previous
      request when paginating.

      We've seen `"before"` and `"after"`, depending on if the pages are in
      ascending or descending order.
  """
  @enforce_keys [:format]
  defstruct [
    :format,
    :extract_key,
    :page_arg,
    params: [],
  ]

  def bind(%__MODULE__{} = self, params) when is_list(params),
    do: %{self | params: params}

  def to_path(%__MODULE__{} = self) do
    encoded_params =
      self.params
      |> Enum.map(fn {k, v} ->
        {k, v |> to_string() |> URI.encode_www_form()}
      end)

    self.format |> EEx.eval_string(encoded_params)
  end

end # defmodule Subscrape.Endpoint

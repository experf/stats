defmodule CortexWeb.FormHelpers do
  use Phoenix.HTML
  import CortexWeb.ErrorHelpers
  import CortexWeb.ClassHelpers
  require Logger

  @form_json_editor_class "form-json-editor"

  def add_valid_class(to, form_data, field) do
    if has_error?(form_data.source, field) do
      to |> add_class("is-invalid")
    else
      to
    end
  end

  def json_editor(form_data, field, opts \\ []) do
    {data, opts} = Keyword.split(opts, [:schema, :templates])

    content_tag :div, [
      {:data, data} | opts |> add_class(@form_json_editor_class)
    ] do
      [
        hidden_input(
          form_data,
          field,
          [class: "#{@form_json_editor_class}-input"]
          |> add_valid_class(form_data, field)
        ),
        error_tag(form_data, field),
        content_tag(
          :div,
          "",
          class: "#{@form_json_editor_class}-container"
        )
      ]
    end
  end
end

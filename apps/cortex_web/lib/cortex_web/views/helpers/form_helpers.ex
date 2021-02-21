defmodule CortexWeb.FormHelpers do
  require Logger
  use Phoenix.HTML
  import CortexWeb.ErrorHelpers
  import CortexWeb.ClassHelpers
  alias Cortex.Types.Interval

  @form_json_editor_class "form-json-editor"

  def add_valid_class(to, form, field) do
    if has_error?(form.source, field) do
      to |> add_class("is-invalid")
    else
      to
    end
  end

  def json_editor(form, field, opts \\ []) do
    {data, opts} = Keyword.split(opts, [:schema, :templates])

    content_tag :div, [
      {:data, data} | opts |> add_class(@form_json_editor_class)
    ] do
      [
        hidden_input(
          form,
          field,
          [
            value: input_value(form, field) |> Jason.encode!(),
            class: "#{@form_json_editor_class}-input"
          ]
          |> add_valid_class(form, field)
        ),
        error_tag(form, field),
        content_tag(
          :div,
          "",
          class: "#{@form_json_editor_class}-container"
        )
      ]
    end
  end

  @doc ~S"""
  Render a "Days, hours, minutes, seconds" (DHMS) set of form controls for a
  `field` that stores a `Postgrex.Interval` value.

  The core of the interface is a `div.row` element containing four `div.col` —
  one for each of days, hours, minutes and seconds. Each `.col` contains a
  single `div.form-floating` (see [floating labels]) around a
  `input.form-control[type=number]` and a `label`.

  [floating labels]: https://getbootstrap.com/docs/5.0/forms/floating-labels/

  Above the `.row`, a `div` containing an overall `label` is rendered with the
  `label_content`. A `CortexWeb.ErrorHelpers.error_tag/2` for the `field`
  is added below the `.row`, using the `tag: :div` option.

  The whole thing is wrapped in a `div.form-control-interval-dhms` (a custom
  class).

  The structure looks essentially like:

  ```html
  <div class="form-control-interval-dhms">
    <div>
      <label>label_content</label>
    </div>

    <div class="row">
      <div class="col">
        <div class="form-floating">
          <input class="form-control" type="number" />
          <label>Days</label>
        </div>
      </div>
      <!-- ... -->
    </div>

    <!-- on error: -->
    <div class="invalid-feedback">
  </div>
  ```
  """
  def dhms_control_for_interval(form, field, label_content, opts \\ []) do
    {spacing_size, opts} = opts |> Keyword.pop(:spacing_size, 2)

    spacing_class = "mb-#{spacing_size}"

    content_tag :div, add_class(opts, "form-control-interval-dhms") do
      [
        content_tag(:div, label(form, field, label_content),
          class: spacing_class
        ),
        # Bootstrap 5 form validation wants the `.is-invalid` class on a
        # _sibling_ element that appears _before_ the `.invalid-feedback`
        # element (from `CortexWeb.ErrorHelpers.error_tag/2`) in the markup.
        #
        # > SEE https://getbootstrap.com/docs/5.0/forms/validation/
        #
        # So, here it gets stuck on the `.row`. Not sure how I feel on the whole
        # BS5 form validation stuff, feels annoyingly convoluted so far.
        content_tag(:div, dhms_input_cols(form, field),
          class:
            "row" |> add_class(spacing_class) |> add_valid_class(form, field)
        ),
        error_tag(form, field, tag: :div)
      ]
    end
  end

  defp dhms_input_cols(form, field) do
    for {sub_field, sub_value} <-
          form |> input_value(field) |> Interval.to_dhms() do
      id = "#{input_id(form, field)}_#{sub_field}"

      content_tag :div, class: "col" do
        content_tag :div, class: "form-floating" do
          [
            tag(
              :input,
              type: :number,
              id: id,
              name: input_name(form, field) <> "[#{sub_field}]",
              value: sub_value,
              class: "form-control" |> add_valid_class(form, field)
            ),
            content_tag(
              :label,
              Interval.humanize(sub_field),
              for: id
            )
          ]
        end
      end
    end
  end
end

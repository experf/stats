defmodule CortexWeb.ScraperView do
  use CortexWeb, :view

  use Phoenix.HTML

  alias Cortex.Scrapers.Scraper

  def module_options() do
    Scraper.module_values()
    |> Enum.map(fn module ->
      string = Atom.to_string(module)
      name = string |> String.replace(~r/^Elixir\./, "")
      {name, string}
    end)
  end

  def sub_input_id(form, field, sub_field) do
    "#{input_id(form, field)}_#{sub_field}"
  end

  def sub_number_input(form, {field, sub_field}, opts \\ []) do
    tag(
      :input,
      [
        type: :number,
        id: sub_input_id(form, field, sub_field),
        name: input_name(form, field) <> "[#{sub_field}]",
        value: sub_input_value(form, field, sub_field)
      ] |> Keyword.merge(opts)
    )
  end

  def interval_hours(form, field) do
    case form |> input_value(field) do
      nil -> 0
      interval -> interval.secs |> div(60 * 60)
    end
  end

  def interval_mins_rem(form, field) do
    case form |> input_value(field) do
      nil -> 0
      interval -> interval.secs |> rem(60 * 60) |> div(60)
    end
  end

  def interval_secs_rem(form, field) do
    case form |> input_value(field) do
      nil -> 0
      interval -> rem(interval.secs, 60)
    end
  end

  def sub_input_value(form, field, sub_field) do
    form |> input_value(field) |> Map.get(sub_field, 0)
  end

  def sub_label(form, fields),
    do: sub_label(form, fields, [])

  def sub_label(form, fields, do_block_or_text_or_opts)

  def sub_label(form, fields, do: block),
    do: sub_label(form, fields, [], do: block)

  def sub_label(form, fields, text)
      when is_binary(text),
      do: sub_label(form, fields, text, [])

  def sub_label(form, {_field, sub_field} = fields, opts)
      when is_list(opts),
      do: sub_label(form, fields, humanize(sub_field), opts)

  def sub_label(form, fields, text_or_opts, do_block_or_opts)

  def sub_label(form, fields, opts, do: block)
      when is_list(opts),
      do: sub_label(form, fields, block, opts)

  def sub_label(form, {field, sub_field}, text_or_block, opts)
      when is_list(opts) do
    content_tag(
      :label,
      text_or_block,
      opts |> Keyword.put_new(:for, sub_input_id(form, field, sub_field))
    )
  end
end

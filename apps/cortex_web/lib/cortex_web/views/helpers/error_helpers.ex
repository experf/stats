defmodule CortexWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  require Logger

  use Phoenix.HTML
  use Birdstrap.HTML

  @doc """
  Generates tags for form input errors.

  The default implementation returned a list of `span` tags (one for each error
  present for the `field` — yeah, a single `field` may have multiple errors),
  but I've changed it to:

  1.  Wrap the whole thing in a outer tag, which has `.invalid-feedback` class
      (it needs to be a _sibling_ of the invalid `<input>`).
  2.  Use `<div>` by default for both the outer and per-error tags. Made more
      sense to me. You can change this with an option.

  Outer tag gets a custom `.field-errors` class, and inners get custom
  `.field-errors`. Using the default `<div>` ths structure is:

  ```html
  <div class="field-errors invalid-feedback">
    <div class="field-error">...</div>
    <!-- ... -->
  </div>
  ```

  ## Parameters

  -   `form`  — the `Phoenix.HTML.Form` being rendered.
  -   `field` — name of the field to render errors for.
  -   `opts`  — become the HTML attributes of the _outer_ tag, except:
      -   `outer_tag:` — tag name to use for the _outer_ tag, default `:div`.
      -   `inner_tag:` — tag name to use for the _inner_ tag, default `:div`.

      For example, you can make it render an ordered list like:

          error_tag form, field, outer_tag: :ol, inner_tag: :li

  ## Notes

  1.  I wanted to move this into `Birdstrap` since it has to do with Bootstrap
      integration, but I realized it's probably dup'd out here in every Phoenix
      project because it calls `translate_error/1`, which uses `CortexWeb`.

      So here it stays.
  """
  def error_tag(form, field, opts \\ []) do
    {outer_tag_name, opts} = opts |> Keyword.pop(:outer_tag, :div)
    {inner_tag_name, opts} = opts |> Keyword.pop(:inner_tag, :div)
    attrs =
      opts
      |> add_class("field-errors")
      |> add_class("invalid-feedback")
      |> Keyword.put_new(:phx_feedback_for, input_id(form, field))

    content_tag outer_tag_name, attrs do
      for error <- Keyword.get_values(form.errors, field) do
        content_tag(
          inner_tag_name,
          translate_error(error),
          class: "field-error"
        )
      end
    end
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(CortexWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(CortexWeb.Gettext, "errors", msg, opts)
    end
  end

  def was_validated?(%Ecto.Changeset{} = changeset) do
    if Enum.empty?(changeset.errors), do: "", else: "was-validated:invalid"
  end

  def has_error?(%Ecto.Changeset{} = changeset, field) do
    changeset.errors |> Keyword.has_key?(field)
  end

  # def errors_for(%Ecto.Changeset{} = changeset) do
  #   Enum.map changeset.errors,
  #     fn {field, detail} ->
  #       %{
  #         message: render_error_detail(detail),
  #         field: Absinthe.Utils.camelize(to_string(field), lower: true),
  #       }
  #     end
  # end

  # # @spec render_error_details({String.t, Keyword.t})
  # defp render_error_detail({message, values}) do
  #   Enum.reduce values, message, fn {key, value}, acc ->
  #     String.replace(acc, "%{#{key}}", value_to_string(value))
  #   end
  # end

  # defp value_to_string(value) when is_binary(value), do: value

  # defp value_to_string(value) when is_atom(value), do: to_string(value)

  # defp value_to_string(value) when is_list(value) do
  #   Enum.map(value, fn entry -> value_to_string(entry) end)
  #   |> Enum.join(", ")
  # end
end

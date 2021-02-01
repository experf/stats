defmodule CortexWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  require Logger

  use Phoenix.HTML

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      content_tag(:span, translate_error(error),
        class: "invalid-feedback",
        phx_feedback_for: input_id(form, field)
      )
    end)
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

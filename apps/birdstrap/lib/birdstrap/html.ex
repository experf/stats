defmodule Birdstrap.HTML do
  @doc ~S"""
  `import` all the HTML functionality. Like `use Phoenix.HTML`.
  """
  defmacro __using__(_) do
    quote do
      import Birdstrap.HTML.Class
      import Birdstrap.HTML.Grid
    end
  end
end

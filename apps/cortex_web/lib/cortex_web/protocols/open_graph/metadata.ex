defimpl Phoenix.HTML.Safe, for: Cortex.OpenGraph.Metadata do
  def to_iodata(open_graph_metadata) do
    open_graph_metadata
    |> Jason.encode!()
    |> Phoenix.HTML.Safe.to_iodata()
  end
end

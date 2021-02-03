defmodule Cortex.Events do
  require Logger

  @topic "events"

  def produce(props) when is_map(props) do
    Logger.debug("Producing event", props |> Map.to_list())
    value = Jason.encode!(props)
    case :brod_client.get_partitions_count(:cortex, @topic) do
      {:ok, partitions_cnt} ->
        partitions = 0..partitions_cnt - 1 |> Enum.shuffle
        try_produce(@topic, partitions, "", value, nil)
      {:error, _} = error ->
        Logger.error("#{inspect error}")
        error
    end
  end

  defp try_produce(_topic, [], _key, _value, error) do
    Logger.error("#{inspect error}")
    error
  end
  defp try_produce(topic, [p | partitions], key, value, _last_error) do
    case :brod.produce_sync_offset(:cortex, topic, p, key, value) do
      {:ok, _offset} = success ->
        success
      {:error, :unknown_topic_or_partition} = error ->
        Logger.error("#{inspect error}")
        # does not make sense to try other partitions
        error
      {:error, {:producer_not_found, _topic}} = error ->
        Logger.error("#{inspect error}")
        # does not make sense to try other partitions
        error
      {:error, {:producer_not_found, _topic, _p}} = error ->
        Logger.error("#{inspect error}")
        # does not make sense to try other partitions
        error
      {:error, :leader_not_available} = error ->
        Logger.error("#{inspect error}")
        try_produce(topic, partitions, key, value, error)
      {:error, :not_leader_for_partition} = error ->
        Logger.error("#{inspect error}")
        try_produce(topic, partitions, key, value, error)
      error ->
        Logger.error("#{inspect error}")
        error
    end
  end
end

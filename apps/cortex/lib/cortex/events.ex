defmodule Cortex.Events do
  require Logger

  @topic "events"

  # SEE https://github.com/klarna/brod#supported-message-input-format

  def encode!(props), do: props |> Jason.encode!()

  def to_ts(%DateTime{} = datetime),
    do: datetime |> DateTime.to_unix(:millisecond)

  def to_ts(ts) when is_integer(ts), do: ts

  def to_key(nil), do: ""
  def to_key(key) when is_binary(key), do: key

  def to_value!(value) when is_binary(value), do: value
  def to_value!(value), do: value |> encode!()

  @doc ~S"""

  ## See

  1.  https://github.com/klarna/brod#supported-message-input-format

  ## Examples

  1.
  """
  def prepare(event)

  def prepare(value) when is_binary(value), do: value

  def prepare(batch) when is_list(batch),
    do: for(data <- batch, do: data |> prepare_batch_entry())

  def prepare({ts, value}),
    do: {ts |> to_ts(), value |> to_value!()}

  def prepare(%{ts: ts, value: value} = event) do
    event
    |> Map.merge(%{
      ts: ts |> to_ts(),
      value: value |> to_value!()
    })
  end

  def prepare(%{value: value} = event) do
    event
    |> Map.merge(%{
      value: value |> to_value!()
    })
  end

  def prepare(%{type: type, app: app} = props)
      when is_binary(type) and is_binary(app),
      do: props |> encode!()

  def prepare_batch_entry(%{ts: ts, key: key, value: value} = event) do
    event
    |> Map.merge(%{
      ts: ts |> to_ts(),
      key: key |> to_key(),
      value: value |> to_value!()
    })
  end

  def prepare_batch_entry(%{key: key, value: value} = event) do
    event
    |> Map.merge(%{
      key: key |> to_key(),
      value: value |> to_value!()
    })
  end

  # Handles the `[{key, value}, ...]` batch format. To trigger this path `key`
  # **_must_** be `nil` or a `binary`, otherwise the first term is assumed to
  # represent a timestamp.
  def prepare_batch_entry({key, value}) when is_nil(key) or is_binary(key),
    do: {key |> to_key(), value |> to_value!()}

  # Handles the `{timestamp, value}` single-event format.
  #
  # [brod][] _seems_ to say that this format is _not_ acceptable in batch,
  # but the `{timestamp, key, value}` format clearly is, so we just convert to
  # that by adding an empty `""` key.
  #
  def prepare_batch_entry({ts, value}),
    do: {ts |> to_ts(), "", value |> to_value!()}

  # Handles the `[{timestamp, key, value}, ...]` batch format.
  def prepare_batch_entry({ts, key, value}) when is_nil(key) or is_binary(key),
    do: {
      ts |> to_ts(),
      key |> to_key(),
      value |> to_value!()
    }

  def produce(data, opts \\ []) when is_list(opts) do
    key = opts |> Keyword.get(:key, "") |> to_key()
    value = prepare(data)

    case :brod_client.get_partitions_count(:cortex, @topic) do
      {:ok, partitions_cnt} ->
        partitions = 0..(partitions_cnt - 1) |> Enum.shuffle()
        try_produce(@topic, partitions, key, value, nil)

      {:error, _} = error ->
        Logger.error("#{inspect(error)}")
        error
    end
  end

  def produce!(data, opts \\ []) do
    case produce(data, opts) do
      {:ok, _offset} = ok -> ok
      {:error, reason} -> raise RuntimeError, inspect(reason)
    end
  end

  # def produce(props, unix_ms)
  #     when is_integer(unix_ms) and is_map(props) do
  #   # Logger.debug("Producing event", props |> Map.to_list())
  #   value = %{ts: unix_ms, value: Jason.encode!(props)}

  #   case :brod_client.get_partitions_count(:cortex, @topic) do
  #     {:ok, partitions_cnt} ->
  #       partitions = 0..(partitions_cnt - 1) |> Enum.shuffle()
  #       try_produce(@topic, partitions, "", value, nil)

  #     {:error, _} = error ->
  #       Logger.error("#{inspect(error)}")
  #       error
  #   end
  # end

  # def produce(%{ts: ts, value: value})
  #     when is_integer(ts) and is_map(value) do
  #   Logger.debug("Producing event", value |> Map.to_list())
  #   value_s = value |> Jason.encode!()

  #   case :brod_client.get_partitions_count(:cortex, @topic) do
  #     {:ok, partitions_cnt} ->
  #       partitions = 0..(partitions_cnt - 1) |> Enum.shuffle()
  #       try_produce(@topic, partitions, "", %{ts: ts, value: value_s}, nil)

  #     {:error, _} = error ->
  #       Logger.error("#{inspect(error)}")
  #       error
  #   end
  # end

  # def produce(props) when is_map(props) do
  #   Logger.debug("Producing event", props |> Map.to_list())
  #   value = Jason.encode!(props)

  #   case :brod_client.get_partitions_count(:cortex, @topic) do
  #     {:ok, partitions_cnt} ->
  #       partitions = 0..(partitions_cnt - 1) |> Enum.shuffle()
  #       try_produce(@topic, partitions, "", value, nil)

  #     {:error, _} = error ->
  #       Logger.error("#{inspect(error)}")
  #       error
  #   end
  # end

  defp try_produce(_topic, [], _key, _value, error) do
    Logger.error("#{inspect(error)}")
    error
  end

  defp try_produce(topic, [p | partitions], key, value, _last_error) do
    case :brod.produce_sync_offset(:cortex, topic, p, key, value) do
      {:ok, _offset} = ok ->
        ok

      {:error, :unknown_topic_or_partition} = error ->
        Logger.error("#{inspect(error)}")
        # does not make sense to try other partitions
        error

      {:error, {:producer_not_found, _topic}} = error ->
        Logger.error("#{inspect(error)}")
        # does not make sense to try other partitions
        error

      {:error, {:producer_not_found, _topic, _p}} = error ->
        Logger.error("#{inspect(error)}")
        # does not make sense to try other partitions
        error

      {:error, :leader_not_available} = error ->
        Logger.error("#{inspect(error)}")
        try_produce(topic, partitions, key, value, error)

      {:error, :not_leader_for_partition} = error ->
        Logger.error("#{inspect(error)}")
        try_produce(topic, partitions, key, value, error)

      error ->
        Logger.error("#{inspect(error)}")
        error
    end
  end
end

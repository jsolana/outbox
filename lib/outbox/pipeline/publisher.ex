defmodule Outbox.Pipeline.Publisher do
  @moduledoc """
  Outbox publisher is responsible to consume events from reader and publish them to the message broker.
  Takes next options on startup:
  - `:publisher`: publisher module client to send messages to the message broker
  - `:consumer_max_demand`: maximum publisher demand, can be useful for tuning.
  Defaults to 1. See `GenStage` documentation for more info.
  - `:consumer_min_demand`: minimum publisher demand, can be useful for tuning.
  Defaults to 0. See `GenStage` documentation for more info.
  """
  use GenStage

  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(opts) do
    publisher = Keyword.fetch!(opts, :publisher)
    min_demand = Keyword.fetch!(opts, :consumer_min_demand)
    max_demand = Keyword.fetch!(opts, :consumer_max_demand)

    {:producer_consumer,
     %{
       publisher: publisher
     }, subscribe_to: [{Outbox.Pipeline.Reader, min_demand: min_demand, max_demand: max_demand}]}
  end

  def handle_events(events, _from, state) do
    {success, error} =
      events
      |> Enum.reduce({[], []}, fn event, {success, error} ->
        publish(event, state, success, error)
      end)

    events = [
      {:success_batch, {hd(events).type, Enum.map(success, & &1.id)}},
      {:error_batch, {hd(events).type, Enum.map(error, & &1.id)}}
    ]

    {:noreply, events, state}
  end

  defp publish(event, state, success, error) do
    :telemetry.span(
      [:outbox, :publish],
      %{},
      fn ->
        result =
          case event
               |> Outbox.Types.OutboxEvent.parse_changeset_to_event()
               |> state.publisher.publish() do
            :ok ->
              {[event | success], error}

            _ ->
              {success, [event | error]}
          end

        {result, %{type: event.type}}
      end
    )
  end
end

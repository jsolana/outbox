defmodule Outbox.Pipeline.Acknowledger do
  @moduledoc """
  Outbox ack. Stage that updates in the database the messages that were published.
  Takes next options on startup:
  - `:repo`: the repo to perform ack updates
  - `:query_opts`: A list of options sent to Repo calls.
  - `:consumer_max_demand`: maximum publisher demand, can be useful for tuning.  Defaults to 1. See `GenStage` documentation for more info.
  - `:consumer_min_demand`: minimum publisher demand, can be useful for tuning.  Defaults to 0. See `GenStage` documentation for more info.
  """
  use GenStage

  alias Outbox.Repository

  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(opts) do
    repo = Keyword.fetch!(opts, :repo)
    min_demand = Keyword.fetch!(opts, :consumer_min_demand)
    max_demand = Keyword.fetch!(opts, :consumer_max_demand)
    query_opts = Keyword.fetch!(opts, :query_opts)

    {:consumer,
     %{
       repo: repo,
       query_opts: query_opts
     },
     subscribe_to: [
       {Outbox.Pipeline.Publisher, min_demand: min_demand, max_demand: max_demand}
     ]}
  end

  def handle_events(events, _from, state) do
    Enum.each(events, &handle_event(&1, state))
    {:noreply, [], state}
  end

  # empty batches
  defp handle_event({_, {_, []}}, state), do: {:noreply, [], state}

  defp handle_event({:success_batch, {type, items}}, state) do
    Repository.update_success_batch(
      state.repo,
      items,
      type,
      state.query_opts
    )
  end

  defp handle_event({:error_batch, {type, items}}, state) do
    Repository.update_error_batch(
      state.repo,
      items,
      type,
      state.query_opts
    )
  end
end

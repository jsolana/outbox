defmodule Outbox.Rescuer do
  @moduledoc """
  Recuer process responsible to rescues messages stuck in publishing state.
  Takes next options on startup:
  - `:repo`: the repo to perform the rescue
  - `:query_opts`: A list of options sent to Repo calls.
  - `:rescuer_interval_ms`: the interval between rescuer runs. Notice that it always runs on tstartup.
  - `rescuer_limit_ms`: the time limit for records to be in the publishing state. Notice that they may stay longer in this state due to the interval.
  """

  use GenServer

  alias Outbox.Repository

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  def init(opts) do
    repo = Keyword.fetch!(opts, :repo)
    query_opts = Keyword.fetch!(opts, :query_opts)
    interval_ms = Keyword.fetch!(opts, :rescuer_interval_ms)
    limit_ms = Keyword.fetch!(opts, :rescuer_limit_ms)

    {:ok, %{repo: repo, query_opts: query_opts, interval_ms: interval_ms, limit_ms: limit_ms},
     {:continue, :rescue}}
  end

  @impl GenServer
  def handle_continue(:rescue, state) do
    Repository.rescue_publishing(state.repo, state.limit_ms, state.query_opts)

    {:noreply, state, {:continue, :schedule_next}}
  end

  def handle_continue(:schedule_next, state) do
    :erlang.send_after(state.interval_ms, self(), :rescue)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:rescue, state) do
    {:noreply, state, {:continue, :rescue}}
  end
end

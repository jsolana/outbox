defmodule Outbox.Cleaner do
  @moduledoc """
  Clean messages that were already published and delete them.
  Takes next options on startup:
  - `:repo`: the repo to perform cleanning
  - `:query_opts`: A list of options sent to Repo calls.
  - `:cleaner_interval_ms`: the interval between cleaner runs. Notice that it always runs on startup.
  - `:cleaner_limit_ms`: the time limit for published records to be in the table.
  """

  use GenServer

  alias Outbox.Repository

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    repo = Keyword.fetch!(opts, :repo)
    query_opts = Keyword.fetch!(opts, :query_opts)
    interval_ms = Keyword.fetch!(opts, :cleaner_interval_ms)
    limit_ms = Keyword.fetch!(opts, :cleaner_limit_ms)

    {:ok, %{repo: repo, query_opts: query_opts, interval_ms: interval_ms, limit_ms: limit_ms},
     {:continue, :cleanning}}
  end

  @impl true
  def handle_continue(:cleanning, state) do
    Repository.clean_messages(state.repo, state.limit_ms, state.query_opts)
    {:noreply, state, {:continue, :schedule_next}}
  end

  def handle_continue(:schedule_next, state) do
    :erlang.send_after(state.interval_ms, self(), :cleanning)
    {:noreply, state}
  end

  @impl true
  def handle_info(:cleanning, state) do
    {:noreply, state, {:continue, :cleanning}}
  end
end

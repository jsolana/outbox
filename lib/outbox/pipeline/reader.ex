defmodule Outbox.Pipeline.Reader do
  @moduledoc """
  Outbox reader is reponsible to read outbox messages from database and propagate through the pipeline.
  Takes next options on startup:
  - `:repo`: the repo to read outbox messages
  - `:query_opts`: A list of options sent to Repo calls.
  - `:poll_interval_ms`: the interval between read_outbox_messages runs (to check new messages).
  """
  use GenStage
  alias Outbox.Repository

  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(opts) do
    repo = Keyword.fetch!(opts, :repo)
    query_opts = Keyword.fetch!(opts, :query_opts)
    poll_interval = Keyword.fetch!(opts, :reader_poll_interval_ms)

    {:producer,
     %{
       repo: repo,
       query_opts: query_opts,
       poll_interval: poll_interval
     }}
  end

  def handle_info(:polling, state) do
    read_outbox_messages(1, state)
  end

  def handle_demand(demand, state) do
    read_outbox_messages(demand, state)
  end

  defp read_outbox_messages(demand, state) do
    case Repository.fetch_pending_messages(state.repo, demand, state.query_opts) do
      {:ok, messages} when is_list(messages) and length(messages) > 0 ->
        {:noreply, messages, state}

      _response ->
        state.poll_interval
        |> send_tick_after_poll_interval()

        {:noreply, [], state}
    end
  end

  defp send_tick_after_poll_interval(poll_interval) do
    Process.send_after(self(), :polling, poll_interval)
  end
end

defmodule Outbox.Pipeline.AcknowledgerwithSupervisor do
  @moduledoc """
  Outbox ack with supervisor. Stage that updates in the database the messages that were published.
  Takes next options on startup:
  - `:repo`: the repo to perform ack updates
  - `:query_opts`: A list of options sent to Repo calls.
  """
  alias Outbox.Repository

  def start_link(args, event) do
    repo = Keyword.fetch!(args, :repo)
    query_opts = Keyword.fetch!(args, :query_opts)

    Task.start_link(fn ->
      case event do
        {:success_batch, {type, items}} when is_list(items) and length(items) > 0 ->
          Repository.update_success_batch(
            repo,
            items,
            type,
            query_opts
          )

        {:error_batch, {type, items}} when is_list(items) and length(items) > 0 ->
          Repository.update_error_batch(
            repo,
            items,
            type,
            query_opts
          )

        _ ->
          # ignored
          :ok
      end
    end)
  end
end

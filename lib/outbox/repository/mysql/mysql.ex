defmodule Outbox.Repository.MySQL do
  @moduledoc """
  Specific function implementation for MySQL adapter
  """
  import Ecto.Query
  alias Outbox.Repository.Schemas.Message

  def fetch_pending_messages(repo, demand, query_opts \\ []) do
    subset =
      Message
      |> where([m], m.state in [:pending, :error])
      |> order_by([m], m.id)
      |> limit(^demand)

    repo.transaction(
      fn ->
        get_lock(repo, query_opts)
        messages = repo.all(subset, query_opts)

        ids = Enum.map(messages, fn message -> message.id end)

        Message
        |> where([m], m.id in ^ids)
        |> update([m],
          set: [
            state: :publishing,
            attempted_at: fragment("CURRENT_TIMESTAMP")
          ],
          inc: [attempt: 1]
        )
        |> repo.update_all([], query_opts)

        release_lock(repo, query_opts)
        messages
      end,
      query_opts
    )
  end

  @lock_name "outbox_lock"
  @timeout_ms 2000
  defp get_lock(repo, query_opts, timeout_ms \\ @timeout_ms) do
    repo.query("SELECT GET_LOCK(?, ?) AS lock_result", [@lock_name, timeout_ms], query_opts)
  end

  defp release_lock(repo, query_opts) do
    repo.query("SELECT RELEASE_LOCK(?) AS release_result", [@lock_name], query_opts)
  end
end

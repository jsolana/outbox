defmodule Outbox.Repository.Postgres do
  @moduledoc """
  Specific function implementation for Postgres adapter
  """
  import Ecto.Query
  alias Outbox.Repository.Schemas.Message

  def fetch_pending_messages(repo, demand, query_opts \\ []) do
    subset =
      Message
      |> select([m], m.id)
      |> where([m], m.state in [:pending, :error])
      |> order_by([m], m.id)
      |> limit(^demand)

    repo.transaction(
      fn ->
        get_lock(repo, query_opts)

        Message
        |> where([m], m.id in subquery(subset))
        |> select([m, _], m)
        |> update([m],
          set: [
            state: :publishing,
            attempted_at: fragment("CURRENT_TIMESTAMP")
          ],
          inc: [attempt: 1]
        )
        |> repo.update_all([], query_opts)
        |> case do
          {0, nil} ->
            {0, []}

          {_count, messages} ->
            Enum.sort(messages, fn m1, m2 -> m1.id <= m2.id end)
        end
      end,
      query_opts
    )
  end

  @lock_key 1_123_456_111_001
  defp get_lock(repo, query_opts) do
    repo.query!("SELECT pg_advisory_xact_lock($1)", [@lock_key], query_opts)
  end
end

defmodule Outbox.Repository do
  @moduledoc """
  Module With all the operations against the Outbox table
  """

  alias Outbox.Repository.MySQL
  alias Outbox.Repository.Postgres
  alias Outbox.Repository.Schemas.Message
  import Ecto.Query
  require Logger

  def fetch_pending_messages(repo, demand, query_opts \\ []) do
    case repo.__adapter__ do
      Ecto.Adapters.MyXQL ->
        MySQL.fetch_pending_messages(repo, demand, query_opts)

      Ecto.Adapters.Postgres ->
        Postgres.fetch_pending_messages(repo, demand, query_opts)

      adapter ->
        Logger.warning("Adapter #{inspect(adapter)} not supported!")
        # Ecto.Adapters.Tds
        {:ok, []}
    end
  end

  def update_success_batch(repo, ids, type, query_opts \\ []) do
    result =
      from(Message)
      |> where([m], m.id in ^ids)
      |> repo.update_all(
        [set: [state: :published, published_at: DateTime.utc_now() |> DateTime.to_naive()]],
        query_opts
      )

    :telemetry.execute([:outbox, :events_published], %{delta: length(ids)}, %{
      type: type
    })

    result
  end

  def update_error_batch(repo, ids, type, query_opts \\ []) do
    result =
      from(Message)
      |> where([m], m.id in ^ids)
      |> repo.update_all(
        [set: [state: :error]],
        query_opts
      )

    :telemetry.execute([:outbox, :events_error], %{delta: length(ids)}, %{
      type: type
    })

    result
  end

  def clean_messages(repo, time_limit_ms, query_opts \\ []) do
    time_limit_s = time_limit_ms / 1000

    register_to_delete =
      from(Message)
      |> where([m], m.state == :published)
      |> where([m], m.published_at < ago(^time_limit_s, "second"))
      |> repo.all(query_opts)

    if length(register_to_delete) > 0 do
      ids = Enum.map(register_to_delete, fn register -> register.id end)
      from(Message) |> where([m], m.id in ^ids) |> repo.delete_all(query_opts)

      :telemetry.execute([:outbox, :events_cleaned], %{delta: length(register_to_delete)}, %{
        type: hd(register_to_delete).type
      })
    end

    register_to_delete
  end

  def rescue_publishing(repo, time_limit_ms, query_opts \\ []) do
    time_limit_s = time_limit_ms / 1000

    register_to_recover =
      from(Message)
      |> where([m], m.state == :publishing)
      |> where([m], m.attempted_at < ago(^time_limit_s, "second"))
      |> repo.all(query_opts)

    if length(register_to_recover) > 0 do
      ids = Enum.map(register_to_recover, fn register -> register.id end)

      from(Message)
      |> where([m], m.id in ^ids)
      |> update([m], set: [state: :pending])
      |> repo.update_all([], query_opts)

      :telemetry.execute([:outbox, :events_recovered], %{delta: length(register_to_recover)}, %{
        type: hd(register_to_recover).type
      })
    end

    register_to_recover
  end
end

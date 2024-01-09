defmodule Outbox.Migrator do
  @moduledoc """
  Module responsible to migrate outbox schema
  """

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def init(opts) do
    {:ok, _} = Application.ensure_all_started(:outbox)
    {repo, _opts} = Keyword.pop!(opts, :repo)
    path = Application.app_dir(:outbox, "priv/repository/migrations")
    Ecto.Migrator.run(repo, path, :up, all: true)
    {:ok, opts}
  end
end

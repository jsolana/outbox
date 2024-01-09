defmodule Outbox.Supervisor do
  # See https://hexdocs.pm/elixir/Supervisor.html
  # for more information on Supervisor behaviour
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(opts) do
    children = [
      {Outbox.Migrator, opts},
      {Outbox.Pipeline.Reader, opts},
      {Outbox.Pipeline.Publisher, opts},
      {Outbox.Pipeline.AcknowledgerSupervisor, opts},
      {Outbox.Cleaner, opts},
      {Outbox.Rescuer, opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Outbox.Pipeline.AcknowledgerSupervisor do
  @moduledoc """
  Ack supervisor.
  Takes next options on startup:
  - `:acknowledger_max_demand`: how many processes it needs to start according to the demand.
  """
  use ConsumerSupervisor

  def start_link(args) do
    ConsumerSupervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    max_demand = Keyword.fetch!(args, :acknowledger_max_demand)

    children = [
      %{
        id: Outbox.Pipeline.AcknowledgerwithSupervisor,
        start: {Outbox.Pipeline.AcknowledgerwithSupervisor, :start_link, [args]},
        restart: :transient
      }
    ]

    opts = [
      strategy: :one_for_one,
      subscribe_to: [{Outbox.Pipeline.Publisher, max_demand: max_demand}]
    ]

    ConsumerSupervisor.init(children, opts)
  end
end

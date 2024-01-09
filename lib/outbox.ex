defmodule Outbox do
  @moduledoc """
  A blazing outbox pattern support in pure Elixir.
  Accepts the following opts:
    - `:repo`: the repo where messages will be read from. Usually should be the same repo that you're writing to. **Mandatory**.
    - `:publisher`: module responsible to emit the outbox message to an external messagery broker. **Mandatory**.  This module needs to implement a `publish/1` function where Outbox.Types.OutboxEvent data is going to be sent.
    - `:reader_poll_interval_ms`: Reader time between polling checking for pending messages to be sent. By default: 10_000.
    - `:consumer_min_demand`: Minimal demand configured for the consumer (ack), producer_consumer(publisher). By default `0`. See `GenStage` documentation for more info.
    - `:consumer_max_demand`: Minimal demand configured for the consumer (ack), producer_consumer(publisher). By default `1`. See `GenStage` documentation for more info.
    - `:rescuer_interval_ms`: Rescuer process interval. By default `:timer.seconds(15)`.
    - `:rescuer_limit_ms`: The time limit for records to be in the publishing state. By default `:timer.seconds(15)`.
    - `:cleaner_interval_ms`: Cleaner process interval. By default `:timer.seconds(30)`.
    - `:cleaner_limit_ms`: Cleaner time window (retention policy). By default `:timer.hours(168)`.
    - `:query_opts`: Additional options for internal queries. By default `[log: false]`.
    - `:acknowledger_max_demand`: Tell the `Outbox.Pipeline.AcknowledgerSupervisor` how many processes it needs to start according to the demand.

  """
  @spec __using__(keyword) ::
          {:__block__, [],
           [{:@, [...], [...]} | {:def, [...], [...]} | {:defoverridable, [...], [...]}, ...]}
  defmacro __using__(opts) do
    {repo, _opts} = Keyword.pop!(opts, :repo)
    {_publisher, _opts} = Keyword.pop!(opts, :publisher)

    quote do
      @default_opts [
        reader_poll_interval_ms: 10_000,
        consumer_min_demand: 0,
        consumer_max_demand: 1,
        rescuer_interval_ms: :timer.seconds(15),
        rescuer_limit_ms: :timer.seconds(15),
        cleaner_interval_ms: :timer.seconds(30),
        cleaner_limit_ms: :timer.hours(168),
        query_opts: [log: false],
        acknowledger_max_demand: 1
      ]

      @doc """
      Starts an Outbox instance.
      """
      @spec start_link(Keyword.t()) :: {:ok, pid}
      def start_link(opts) do
        Keyword.merge(unquote(opts), opts)
        |> Keyword.validate!([:repo, :publisher])
        |> Outbox.Supervisor.start_link()
      end

      @doc """
      Child spec for an Outbox instance
      """
      @spec child_spec(Keyword.t()) :: Supervisor.child_spec()
      def child_spec(opts) do
        Keyword.merge(unquote(opts), opts)
        |> Keyword.validate!([:repo, :publisher] ++ @default_opts)
        |> Outbox.Supervisor.child_spec()
      end

      @type action() :: :create | :update | :delete
      @doc """
      Publishes a message in the outbox.
      The application must include this call inside a transaction to be effective.
      """
      @spec outbox!(String.t(), term(), action) ::
              {:ok, Outbox.Repository.Schemas.Message.t()} | {:error, atom()}
      def outbox!(type, message, action \\ :create) do
        encode(message)
        |> Outbox.Repository.Schemas.Message.new(type, action)
        |> unquote(repo).insert!()
      end

      @doc """
      Encode your data structure to string
      """
      @spec encode(term()) :: String.t()
      def encode(body) do
        Jason.encode!(body)
      end

      defoverridable encode: 1
    end
  end
end

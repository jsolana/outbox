defmodule Outbox.Repository.Schemas.Message do
  @moduledoc """
  Outbox message schema definition
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type state() ::
          :pending
          | :publishing
          | :published
          | :error

  @type t() :: %__MODULE__{
          id: String.t(),
          state: state(),
          action: String.t(),
          type: String.t(),
          payload: String.t(),
          attempt: pos_integer(),
          attempted_at: NaiveDateTime.t() | nil,
          published_at: NaiveDateTime.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  schema "outbox" do
    field(:type, :string)

    field(:state, Ecto.Enum,
      values: [:pending, :publishing, :published, :error],
      default: :pending
    )

    field(:action, Ecto.Enum,
      values: [:create, :update, :delete],
      default: :create
    )

    field(:payload, :string)
    field(:attempt, :integer, default: 0)

    field(:attempted_at, :naive_datetime)
    field(:published_at, :naive_datetime)

    timestamps()
  end

  @updatable_fields ~w(
  action
  type
  payload
  )a

  @require_fields ~w(
  action
  type
  payload
  )a

  @spec new(String.t(), String.t(), atom()) :: Ecto.Changeset.t()
  def new(payload, type, action \\ :create) do
    %__MODULE__{}
    |> cast(%{type: type, payload: payload, action: action}, @updatable_fields)
    |> validate_required(@require_fields)
  end
end

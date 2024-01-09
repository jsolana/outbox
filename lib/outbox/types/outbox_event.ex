defmodule Outbox.Types.OutboxEvent do
  @moduledoc """
  Representation of an outbox event
  """
  @type t :: %__MODULE__{
          id: String.t(),
          type: String.t(),
          action: atom(),
          payload: any()
        }

  defstruct [
    :id,
    :type,
    :action,
    :payload
  ]

  def parse_changeset_to_event(changeset) do
    %__MODULE__{
      id: changeset.id,
      action: changeset.action,
      type: changeset.type,
      payload: Jason.decode!(changeset.payload)
    }
  end
end

defmodule Outbox.Repository.Migrations.InitialMigration do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:outbox, primary_key: false) do
      add(:id, :bigserial, primary_key: true)
      add(:state, :string, null: false, default: "pending")
      add(:action, :string, null: false, defaukt: "create")
      add(:type, :string, null: false)
      add(:payload, :string)
      add(:attempt, :integer, null: false, default: 0)
      add(:attempted_at, :naive_datetime)
      add(:published_at, :naive_datetime)

      timestamps()
    end

    create(index(:outbox, [:id]))
    create(index(:outbox, [:action]))
    create(index(:outbox, [:type]))
  end
end

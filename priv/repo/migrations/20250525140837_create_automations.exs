defmodule SocialScribe.Repo.Migrations.CreateAutomations do
  use Ecto.Migration

  def change do
    create table(:automations) do
      add :name, :string
      add :type, :string
      add :platform, :string
      add :description, :text
      add :example, :text
      add :is_active, :boolean, default: true, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:automations, [:user_id])
    create unique_index(:automations, [:user_id, :name])
  end
end

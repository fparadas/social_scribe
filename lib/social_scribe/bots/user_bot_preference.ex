defmodule SocialScribe.Bots.UserBotPreference do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_bot_preferences" do
    field :join_minute_offset, :integer
    belongs_to :user, SocialScribe.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_bot_preference, attrs) do
    user_bot_preference
    |> cast(attrs, [:user_id, :join_minute_offset])
    |> validate_required([:user_id, :join_minute_offset])
    |> unique_constraint(:user_id)
  end
end

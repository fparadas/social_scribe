defmodule SocialScribe.AutomationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SocialScribe.Automations` context.
  """

  import SocialScribe.AccountsFixtures

  @doc """
  Generate a automation.
  """
  def automation_fixture(attrs \\ %{}) do
    user_id = attrs[:user_id] || user_fixture().id

    {:ok, automation} =
      attrs
      |> Enum.into(%{
        description: "some description",
        is_active: true,
        name: "some name",
        platform: "some platform",
        example: "some example",
        user_id: user_id
      })
      |> SocialScribe.Automations.create_automation()

    automation
  end
end

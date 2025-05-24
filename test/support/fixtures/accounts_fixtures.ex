defmodule SocialScribe.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SocialScribe.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> SocialScribe.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  @doc """
  Generate a user_credential.
  """
  def user_credential_fixture(attrs \\ %{}) do
    user_id = attrs[:user_id] || user_fixture().id

    {:ok, user_credential} =
      attrs
      |> Enum.into(%{
        user_id: user_id,
        expires_at: ~U[2025-05-23 15:01:00Z],
        provider: "some provider",
        refresh_token: "some refresh_token",
        token: "some token",
        uid: "some uid",
        email: "some email"
      })
      |> SocialScribe.Accounts.create_user_credential()

    user_credential
  end
end

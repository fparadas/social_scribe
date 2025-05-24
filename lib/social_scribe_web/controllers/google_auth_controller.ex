defmodule SocialScribeWeb.GoogleAuthController do
  use SocialScribeWeb, :controller

  alias SocialScribe.Accounts
  alias SocialScribeWeb.UserAuth

  @doc """
  `callback/2` handles the callback from Google Auth API redirect.
  """
  def callback(%{assigns: %{current_user: user}} = conn, %{"code" => code}) do
    case ElixirAuthGoogle.get_token(code, SocialScribeWeb.Endpoint.url()) do
      {:ok, token_data} ->
        {:ok, profile} = ElixirAuthGoogle.get_user_profile(token_data.access_token)

        case Accounts.find_or_create_user_credential(user, profile, token_data) do
          {:ok, _credential} ->
            conn
            |> put_flash(:info, "Google account added successfully.")
            |> redirect(to: ~p"/users/settings")

          {:error, _reason} ->
            conn
            |> put_flash(:error, "Could not add Google account.")
            |> redirect(to: ~p"/users/settings")
        end

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Could not authenticate with Google.")
        |> redirect(to: ~p"/users/settings")
    end
  end

  def callback(conn, %{"code" => code}) do
    case ElixirAuthGoogle.get_token(code, SocialScribeWeb.Endpoint.url()) do
      {:ok, token_data} ->
        {:ok, profile} = ElixirAuthGoogle.get_user_profile(token_data.access_token)

        case Accounts.find_or_create_user_from_google(profile, token_data) do
          {:ok, user} ->
            conn
            |> UserAuth.log_in_user(user)

          {:error, _reason} ->
            conn
            |> put_flash(:error, "There was an error signing you in with Google.")
            |> redirect(to: ~p"/")
        end

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Could not authenticate with Google.")
        |> redirect(to: ~p"/")
    end
  end
end

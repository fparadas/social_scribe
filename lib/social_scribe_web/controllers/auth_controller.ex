defmodule SocialScribeWeb.AuthController do
  use SocialScribeWeb, :controller

  alias SocialScribe.Accounts
  alias SocialScribeWeb.UserAuth
  plug Ueberauth

  @doc """
  Handles the initial request to the provider (e.g., Google).
  Ueberauth's plug will redirect the user to the provider's consent page.
  """
  def request(conn, _params) do
    render(conn, :request)
  end

  @doc """
  Handles the callback from the provider after the user has granted consent.
  """
  def callback(%{assigns: %{ueberauth_auth: auth, current_user: user}} = conn, _params)
      when not is_nil(user) do
    case Accounts.find_or_create_user_credential(user, auth) do
      {:ok, _credential} ->
        conn
        |> put_flash(:info, "Google account added successfully.")
        |> redirect(to: ~p"/dashboard/settings")

      {:error, reason} ->
        dbg(reason)

        conn
        |> put_flash(:error, "Could not add Google account.")
        |> redirect(to: ~p"/dashboard/settings")
    end
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Accounts.find_or_create_user_from_oauth(auth) do
      {:ok, user} ->
        conn
        |> UserAuth.log_in_user(user)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "There was an error signing you in.")
        |> redirect(to: ~p"/")
    end
  end
end

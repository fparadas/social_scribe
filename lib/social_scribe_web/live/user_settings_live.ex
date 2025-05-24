defmodule SocialScribeWeb.UserSettingsLive do
  use SocialScribeWeb, :live_view

  alias SocialScribe.Accounts

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    google_accounts = Accounts.list_user_credentials(current_user, provider: "google")

    oauth_google_url =
      ElixirAuthGoogle.generate_oauth_url(SocialScribeWeb.Endpoint.url(), %{
        access_type: "offline"
      })

    socket =
      socket
      |> assign(:page_title, "User Settings")
      |> assign(:google_accounts, google_accounts)
      |> assign(:oauth_google_url, oauth_google_url)

    {:ok, socket}
  end
end

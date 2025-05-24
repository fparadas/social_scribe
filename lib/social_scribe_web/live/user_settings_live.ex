defmodule SocialScribeWeb.UserSettingsLive do
  use SocialScribeWeb, :live_view

  alias SocialScribe.Accounts

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    google_accounts = Accounts.list_user_credentials(current_user, provider: "google")

    socket =
      socket
      |> assign(:page_title, "User Settings")
      |> assign(:google_accounts, google_accounts)

    {:ok, socket}
  end
end

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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8 md:py-12">
      <h1 class="text-3xl md:text-4xl font-bold mb-8 text-slate-800 dark:text-slate-100">
        {@page_title}
      </h1>

      <div class="bg-white dark:bg-slate-800 shadow-xl rounded-lg p-6 md:p-8">
        <h2 class="text-2xl font-semibold mb-6 text-slate-700 dark:text-slate-200">
          Connected Google Accounts
        </h2>

        <%= if not Enum.empty?(@google_accounts) do %>
          <ul class="space-y-4 mb-8">
            <li
              :for={account <- @google_accounts}
              class="flex justify-between items-center p-4 bg-slate-50 dark:bg-slate-700 rounded-md shadow"
            >
              <div>
                <p class="font-medium text-slate-700 dark:text-slate-200">
                  Google Account
                </p>
                <p class="text-sm text-slate-500 dark:text-slate-400">
                  UID: {account.uid}
                  <%= if account.email do %>
                    ({account.email})
                  <% end %>
                </p>
              </div>
              <!-- Future: Add a "Disconnect" button here -->
            </li>
          </ul>
        <% else %>
          <p class="mb-8 text-slate-600 dark:text-slate-400">
            You haven't connected any Google accounts yet.
          </p>
        <% end %>

        <div>
          <.link
            href={@oauth_google_url}
            method="get"
            class="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 dark:focus:ring-offset-slate-800"
          >
            <svg
              class="-ml-1 mr-3 h-5 w-5"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20"
              fill="currentColor"
              aria-hidden="true"
            >
              <path
                fill-rule="evenodd"
                d="M6 2a2 2 0 00-2 2v12a2 2 0 002 2h8a2 2 0 002-2V4a2 2 0 00-2-2H6zm1 2h6v2H7V4zm0 4h6v2H7V8zm0 4h6v2H7v-2z"
                clip-rule="evenodd"
              />
              <path d="M10 18a8 8 0 100-16 8 8 0 000 16zM5.121 5.121A6.974 6.974 0 0110 3.05a6.974 6.974 0 014.879 1.928.75.75 0 001.06-1.06A8.474 8.474 0 0010 1.55a8.474 8.474 0 00-5.94 2.511.75.75 0 001.06 1.06z" />
            </svg>
            Connect another Google Account
          </.link>
        </div>
      </div>
    </div>
    """
  end
end

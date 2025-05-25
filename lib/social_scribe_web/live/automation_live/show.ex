defmodule SocialScribeWeb.AutomationLive.Show do
  use SocialScribeWeb, :live_view

  alias SocialScribe.Automations

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:automation, Automations.get_automation!(id))}
  end

  @impl true
  def handle_event("toggle_automation", %{"id" => id}, socket) do
    automation = Automations.get_automation!(id)

    {:ok, updated_automation} =
      Automations.update_automation(automation, %{is_active: !automation.is_active})

    {:noreply, assign(socket, :automation, updated_automation)}
  end

  defp page_title(:show), do: "Show Automation"
  defp page_title(:edit), do: "Edit Automation"
end

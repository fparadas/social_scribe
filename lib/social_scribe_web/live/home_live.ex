defmodule SocialScribeWeb.HomeLive do
  use SocialScribeWeb, :live_view

  alias SocialScribe.Calendar
  alias SocialScribe.CalendarSyncronizer
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: send(self(), :sync_calendars)

    socket =
      socket
      |> assign(:page_title, "Upcoming Meetings")
      |> assign(:events, Calendar.list_upcoming_events(socket.assigns.current_user))
      |> assign(:loading, true)

    {:ok, socket}
  end

  @impl true
  def handle_info(:sync_calendars, socket) do
    CalendarSyncronizer.sync_events_for_user(socket.assigns.current_user)

    events = Calendar.list_upcoming_events(socket.assigns.current_user)

    socket =
      socket
      |> assign(:events, events)
      |> assign(:loading, false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_record", %{"id" => event_id}, socket) do
    event = Calendar.get_calendar_event!(event_id)

    {:ok, event} =
      Calendar.update_calendar_event(event, %{record_meeting: not event.record_meeting})

    updated_events =
      Enum.map(socket.assigns.events, fn e ->
        if e.id == event.id, do: event, else: e
      end)

    {:noreply, assign(socket, :events, updated_events)}
  end
end

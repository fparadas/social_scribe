defmodule SocialScribeWeb.MeetingLive.Index do
  use SocialScribeWeb, :live_view

  alias SocialScribe.Meetings

  @impl true
  def mount(_params, _session, socket) do
    meetings = Meetings.list_user_meetings(socket.assigns.current_user)

    socket =
      socket
      |> assign(:page_title, "Past Meetings")
      |> assign(:meetings, meetings)

    {:ok, socket}
  end

  @impl true
  def handle_event("generate_ai_content", %{"id" => meeting_id}, socket) do
    # Placeholder for enqueuing the AI Content Generation job
    # For now, we'll just put a flash message.
    # In the future, this will call something like:
    # AIContentWorker.new(%{meeting_id: meeting_id}) |> Oban.insert()

    # Assuming you have get_meeting!/1
    meeting = Meetings.get_meeting!(meeting_id)

    socket =
      put_flash(
        socket,
        :info,
        "AI content generation started for meeting: '#{meeting.title}'."
      )

    {:noreply, socket}
  end

  defp format_duration(nil), do: "N/A"

  defp format_duration(seconds) when is_integer(seconds) do
    minutes = div(seconds, 60)
    "#{minutes} min"
  end
end

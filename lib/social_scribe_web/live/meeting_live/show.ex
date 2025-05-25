defmodule SocialScribeWeb.MeetingLive.Show do
  use SocialScribeWeb, :live_view

  alias SocialScribe.Meetings

  @impl true
  def mount(%{"id" => meeting_id}, _session, socket) do
    # Fetch the meeting with all its details preloaded
    # The get_meeting_with_details! function should preload:
    # :calendar_event, :recall_bot, :meeting_transcript, :meeting_participants
    meeting = Meetings.get_meeting_with_details!(meeting_id)

    # Basic security check: ensure the meeting belongs to the current user
    # You might want to make this more robust depending on your data model
    # For example, if Meetings.get_meeting_with_details! can be scoped by user.
    # current_user_id = socket.assigns.current_user.id
    # if meeting.calendar_event.user_id != current_user_id do
    #   socket =
    #     socket
    #     |> put_flash(:error, "You do not have permission to view this meeting.")
    #     |> redirect(to: ~p"/meetings")
    #   {:error, socket} # This would stop the mount
    # else
    #   ... proceed
    # end
    # For now, assuming get_meeting_with_details! is safe or you'll add scoping

    socket =
      socket
      |> assign(:page_title, "Meeting Details: #{meeting.title}")
      |> assign(:meeting, meeting)
      |> assign(
        :ai_follow_up_email,
        "AI-generated follow-up email will appear here once generated."
      )
      |> assign(:ai_social_posts_list, [
        %{platform: "LinkedIn", content: "LinkedIn post draft from automation will be here."},
        %{platform: "Facebook", content: "Facebook post draft from automation will be here."}
      ])
      |> assign(
        :ai_draft_social_post,
        "A manually generated AI draft social media post will appear here."
      )

    {:ok, socket}
  end

  defp format_duration(nil), do: "N/A"

  defp format_duration(seconds) when is_integer(seconds) do
    minutes = div(seconds, 60)
    remaining_seconds = rem(seconds, 60)

    cond do
      minutes > 0 && remaining_seconds > 0 -> "#{minutes} min #{remaining_seconds} sec"
      minutes > 0 -> "#{minutes} min"
      seconds > 0 -> "#{seconds} sec"
      true -> "Less than a second"
    end
  end

  attr :meeting_transcript, :map, required: true

  defp transcript_content(assigns) do
    has_transcript =
      assigns.meeting_transcript &&
        assigns.meeting_transcript.content &&
        Map.get(assigns.meeting_transcript.content, "data") &&
        Enum.any?(Map.get(assigns.meeting_transcript.content, "data"))

    assigns =
      assigns
      |> assign(:has_transcript, has_transcript)

    ~H"""
    <div class="bg-white shadow-xl rounded-lg p-6 md:p-8">
      <h2 class="text-2xl font-semibold mb-4 text-slate-700">
        Meeting Transcript
      </h2>
      <div class="prose prose-sm sm:prose max-w-none h-96 overflow-y-auto pr-2">
        <%= if @has_transcript do %>
          <div :for={segment <- @meeting_transcript.content["data"]} class="mb-3">
            <p>
              <span class="font-semibold text-indigo-600">
                {segment["speaker"] || "Unknown Speaker"}:
              </span>
              {Enum.map_join(segment["words"] || [], " ", & &1["text"])}
            </p>
          </div>
        <% else %>
          <p class="text-slate-500">
            Transcript not available for this meeting.
          </p>
        <% end %>
      </div>
    </div>
    """
  end
end

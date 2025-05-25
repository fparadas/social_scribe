defmodule SocialScribe.Workers.AIContentGenerationWorker do
  alias SocialScribe.Meetings.Meeting
  use Oban.Worker, queue: :ai_content, max_attempts: 3

  alias SocialScribe.Meetings
  alias SocialScribe.AIContentGeneratorApi
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"meeting_id" => meeting_id}}) do
    Logger.info("Starting AI content generation for meeting_id: #{meeting_id}")

    case Meetings.get_meeting_with_details(meeting_id) do
      nil ->
        Logger.error("AIContentGenerationWorker: Meeting not found for id #{meeting_id}")
        {:error, :meeting_not_found}

      meeting ->
        process_meeting(meeting)
    end
  end

  defp process_meeting(
         %Meeting{
           id: meeting_id,
           meeting_transcript: %{content: %{"data" => transcript_content}}
         } = meeting
       )
       when not is_nil(transcript_content) do
    case AIContentGeneratorApi.generate_follow_up_email(transcript_content) do
      {:ok, email_draft} ->
        Logger.info("Generated follow-up email for meeting #{meeting_id}")

        case Meetings.update_meeting(meeting, %{follow_up_email: email_draft}) do
          {:ok, _updated_meeting} ->
            Logger.info("Successfully saved AI content for meeting #{meeting_id}")
            :ok

          {:error, changeset} ->
            Logger.error(
              "Failed to save AI content for meeting #{meeting_id}: #{inspect(changeset.errors)}"
            )

            {:error, :db_update_failed}
        end

      {:error, reason} ->
        Logger.error(
          "Failed to generate follow-up email for meeting #{meeting_id}: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  defp process_meeting(%Meeting{} = meeting) do
    Logger.warning(
      "AIContentGenerationWorker: Transcript not available for meeting_id #{meeting.id}. Skipping."
    )

    {:error, :no_transcript}
  end
end

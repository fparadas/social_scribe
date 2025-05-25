defmodule SocialScribe.Workers.AIContentGenerationWorker do
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
        if is_nil(meeting.meeting_transcript) || is_nil(meeting.meeting_transcript.content) ||
             is_nil(Map.get(meeting.meeting_transcript.content, "data")) do
          Logger.warning(
            "AIContentGenerationWorker: Transcript not available for meeting_id #{meeting_id}. Skipping."
          )

          {:error, :no_transcript}
        else
          transcript_content = meeting.meeting_transcript.content["data"]

          case AIContentGeneratorApi.generate_follow_up_email(transcript_content) do
            {:ok, email_draft} ->
              Logger.info("Generated follow-up email for meeting #{meeting_id}")
              ai_attrs = %{follow_up_email: email_draft}

              if map_size(ai_attrs) > 0 do
                case Meetings.update_meeting(meeting, ai_attrs) do
                  {:ok, _updated_meeting} ->
                    Logger.info("Successfully saved AI content for meeting #{meeting_id}")
                    :ok

                  {:error, changeset} ->
                    Logger.error(
                      "Failed to save AI content for meeting #{meeting_id}: #{inspect(changeset.errors)}"
                    )

                    {:error, :db_update_failed}
                end
              else
                Logger.info("No new AI content generated for meeting #{meeting_id}")
                :ok
              end

            {:error, reason} ->
              Logger.error(
                "Failed to generate follow-up email for meeting #{meeting_id}: #{inspect(reason)}"
              )

              {:error, reason}
          end
        end
    end
  end
end

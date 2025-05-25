defmodule SocialScribe.Workers.AIContentGenerationWorkerTest do
  use SocialScribe.DataCase, async: true

  import Mox
  import SocialScribe.MeetingsFixtures
  import SocialScribe.MeetingTranscriptExample

  alias SocialScribe.Workers.AIContentGenerationWorker
  alias SocialScribe.AIContentGeneratorMock, as: AIGeneratorMock
  alias SocialScribe.Meetings

  # Ensure this matches your worker's expectation
  @mock_transcript_data %{"data" => meeting_transcript_example()}
  @generated_email_draft "This is a generated follow-up email draft."

  describe "perform/1" do
    setup do
      stub_with(AIGeneratorMock, SocialScribe.AIContentGenerator)
      :ok
    end

    test "successfully generates and saves a follow-up email" do
      meeting = meeting_fixture()
      meeting_transcript_fixture(%{meeting_id: meeting.id, content: @mock_transcript_data})

      job_args = %{"meeting_id" => meeting.id}

      expect(AIGeneratorMock, :generate_follow_up_email, fn transcript_data ->
        assert transcript_data ==
                 @mock_transcript_data["data"] |> Jason.encode!() |> Jason.decode!()

        {:ok, @generated_email_draft}
      end)

      assert AIContentGenerationWorker.perform(%Oban.Job{args: job_args}) == :ok

      updated_meeting = Meetings.get_meeting_with_details(meeting.id)
      assert updated_meeting.follow_up_email == @generated_email_draft
    end

    test "returns {:error, :meeting_not_found} if meeting_id is invalid" do
      job_args = %{"meeting_id" => System.unique_integer([:positive])}

      assert AIContentGenerationWorker.perform(%Oban.Job{args: job_args}) ==
               {:error, :meeting_not_found}
    end

    test "returns {:error, :no_transcript} if meeting has no transcript content" do
      meeting_with_empty_transcript_content = meeting_fixture()

      job_args_no_data = %{"meeting_id" => meeting_with_empty_transcript_content.id}

      assert AIContentGenerationWorker.perform(%Oban.Job{args: job_args_no_data}) ==
               {:error, :no_transcript}
    end

    test "handles failure from AIContentGenerator.generate_follow_up_email" do
      meeting = meeting_fixture()
      meeting_transcript_fixture(%{meeting_id: meeting.id, content: @mock_transcript_data})

      job_args = %{"meeting_id" => meeting.id}

      expect(AIGeneratorMock, :generate_follow_up_email, fn _ ->
        {:error, :gemini_api_timeout}
      end)

      assert AIContentGenerationWorker.perform(%Oban.Job{args: job_args}) ==
               {:error, :gemini_api_timeout}

      refreshed_meeting = Meetings.get_meeting_with_details(meeting.id)
      assert is_nil(refreshed_meeting.follow_up_email)
    end
  end
end

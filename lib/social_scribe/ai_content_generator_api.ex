defmodule SocialScribe.AIContentGeneratorApi do
  @moduledoc """
  Behaviour for generating AI content for meetings.
  """

  @callback generate_follow_up_email(map()) :: {:ok, String.t()} | {:error, any()}
  @callback generate_automation(map(), map()) :: {:ok, String.t()} | {:error, any()}

  def generate_follow_up_email(meeting) do
    impl().generate_follow_up_email(meeting)
  end

  def generate_automation(automation, meeting) do
    impl().generate_automation(automation, meeting)
  end

  defp impl do
    Application.get_env(
      :social_scribe,
      :ai_content_generator_api,
      SocialScribe.AIContentGenerator
    )
  end
end

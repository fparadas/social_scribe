defmodule SocialScribe.Poster do
  alias SocialScribe.LinkedInApi

  alias SocialScribe.Accounts

  def post_on_social_media(platform, generated_content, current_user) do
    case platform do
      :linkedin -> post_on_linkedin(generated_content, current_user)
      _ -> {:error, "Unsupported platform"}
    end
  end

  defp post_on_linkedin(generated_content, current_user) do
    user_credential = Accounts.get_user_linkedin_credential(current_user)

    LinkedInApi.post_text_share(
      user_credential.token,
      user_credential.uid,
      generated_content
    )
  end
end

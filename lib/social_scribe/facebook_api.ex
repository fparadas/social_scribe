defmodule SocialScribe.FacebookApi do
  @callback post_message_to_page(
              page_id :: String.t(),
              page_access_token :: String.t(),
              message :: String.t()
            ) :: {:ok, String.t()} | {:error, String.t()}

  @callback fetch_user_pages(user_id :: String.t(), user_access_token :: String.t()) ::
              {:ok, [%{id: String.t(), name: String.t()}]} | {:error, String.t()}

  def post_message_to_page(page_id, page_access_token, message) do
    impl().post_message_to_page(page_id, page_access_token, message)
  end

  def fetch_user_pages(user_id, user_access_token) do
    impl().fetch_user_pages(user_id, user_access_token)
  end

  defp impl do
    Application.get_env(:social_scribe, :facebook_api, SocialScribe.Facebook)
  end
end

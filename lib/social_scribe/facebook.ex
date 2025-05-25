defmodule SocialScribe.Facebook do
  @behaviour SocialScribe.FacebookApi

  @base_url "https://graph.facebook.com/v22.0"

  @impl SocialScribe.FacebookApi
  def post_message_to_page(user_id, user_access_token, page_id, message) do
    {:ok, "Post message to page"}
  end

  @impl SocialScribe.FacebookApi
  def fetch_user_pages(user_id, user_access_token) do
    case Tesla.get(client(), "/#{user_id}/accounts?access_token=#{user_access_token}") do
      {:ok, %Tesla.Env{status: 200, body: %{"data" => pages_data}}} ->
        valid_pages =
          Enum.filter(pages_data, fn page ->
            Enum.member?(page["tasks"] || [], "CREATE_CONTENT") ||
              Enum.member?(page["tasks"] || [], "MANAGE")
          end)
          |> Enum.map(fn page ->
            %{
              id: page["id"],
              name: page["name"],
              category: page["category"],
              page_access_token: page["access_token"]
            }
          end)

        {:ok, valid_pages}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "Failed to fetch user pages: #{status} - #{body}"}
    end
  end

  defp client do
    Tesla.client([
      {Tesla.Middleware.BaseUrl, @base_url},
      Tesla.Middleware.JSON
    ])
  end
end

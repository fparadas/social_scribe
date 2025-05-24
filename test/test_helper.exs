ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(SocialScribe.Repo, :manual)

# test/test_helper.exs

Mox.defmock(SocialScribe.GoogleCalendarApiMock, for: SocialScribe.GoogleCalendarApi)
Mox.defmock(SocialScribe.TokenRefresherMock, for: SocialScribe.TokenRefresherApi)
Mox.defmock(SocialScribe.RecallApiMock, for: SocialScribe.RecallApi)

Application.put_env(:social_scribe, :google_calendar_api, SocialScribe.GoogleCalendarApiMock)
Application.put_env(:social_scribe, :token_refresher_api, SocialScribe.TokenRefresherMock)
Application.put_env(:social_scribe, :recall_api, SocialScribe.RecallApiMock)

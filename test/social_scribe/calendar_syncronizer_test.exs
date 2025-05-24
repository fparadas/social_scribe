defmodule SocialScribe.CalendarSyncronizerTest do
  use SocialScribe.DataCase, async: true

  import Mox
  import SocialScribe.AccountsFixtures

  # The context containing the sync logic
  alias SocialScribe.CalendarSyncronizer
  alias SocialScribe.Calendar.CalendarEvent
  alias SocialScribe.TokenRefresherMock
  alias SocialScribe.GoogleCalendarApiMock, as: GoogleApiMock

  # Mock data for a Google Calendar API response
  @mock_google_events [
    %{
      "id" => "zoom-event-123",
      "summary" => "Zoom Meeting",
      "location" => "https://us05web.zoom.us/j/12345",
      "start" => %{"dateTime" => "2025-05-25T10:00:00-03:00"},
      "end" => %{"dateTime" => "2025-05-25T11:00:00-03:00"},
      "status" => "confirmed",
      "htmlLink" => "https://calendar.google.com/calendar/event?eid=zoom-event-123"
    },
    %{
      "id" => "meet-event-456",
      "summary" => "Google Meet Call",
      "hangoutLink" => "https://meet.google.com/abc-def-ghi",
      "start" => %{"dateTime" => "2025-05-26T14:00:00-03:00"},
      "end" => %{"dateTime" => "2025-05-26T14:30:00-03:00"},
      "status" => "confirmed",
      "htmlLink" => "https://calendar.google.com/calendar/event?eid=meet-event-456"
    },
    %{
      "id" => "no-link-event-789",
      "summary" => "Lunch Break",
      "start" => %{"dateTime" => "2025-05-26T12:00:00-03:00"},
      "end" => %{"dateTime" => "2025-05-26T13:00:00-03:00"},
      "status" => "confirmed",
      "htmlLink" => nil
    }
  ]

  describe "sync_events_for_user/1" do
    # Stub only the external dependencies before each test
    setup do
      stub_with(GoogleApiMock, SocialScribe.GoogleCalendar)
      stub_with(TokenRefresherMock, SocialScribe.TokenRefresher)
      :ok
    end

    test "fetches and syncs new events with meeting links to the database" do
      # --- 1. SETUP ---
      user = user_fixture()

      credential =
        user_credential_fixture(%{
          provider: "google",
          user_id: user.id,
          expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
        })

      # Expect the API to be called with specific parameters
      expect(GoogleApiMock, :list_events, fn _token, _start_time, _end_time, calendar_id ->
        assert calendar_id == "primary"
        {:ok, %{"items" => @mock_google_events}}
      end)

      # --- 2. EXECUTION ---
      assert {:ok, :sync_complete} = CalendarSyncronizer.sync_events_for_user(user)

      # --- 3. ASSERTION: Verify the database state ---
      # Assert that only the 2 events with links were saved
      assert Repo.aggregate(CalendarEvent, :count, :id) == 2

      # Check the Zoom event specifically
      zoom_event = Repo.get_by!(CalendarEvent, google_event_id: "zoom-event-123")
      assert zoom_event.summary == "Zoom Meeting"
      assert zoom_event.user_id == user.id
      assert zoom_event.user_credential_id == credential.id

      # Check the Meet event specifically
      meet_event = Repo.get_by!(CalendarEvent, google_event_id: "meet-event-456")
      assert meet_event.summary == "Google Meet Call"

      # Verify the event without a link was NOT saved
      assert Repo.get_by(CalendarEvent, google_event_id: "no-link-event-789") == nil
    end

    # test "refreshes token if expired and then syncs events" do
    #   # --- 1. SETUP ---
    #   user = user_fixture()

    #   credential =
    #     user_credential_fixture(%{
    #       provider: "google",
    #       user_id: user.id,
    #       expires_at: DateTime.add(DateTime.utc_now(), -100, :second)
    #     })

    #   new_token_data = %{"access_token" => "new-refreshed-token", "expires_in" => 3600}
    #   refresh_token = credential.refresh_token

    #   # Expect the token refresher to be called
    #   expect(TokenRefresherMock, :refresh_token, fn ^refresh_token ->
    #     {:ok, new_token_data}
    #   end)

    #   # Expect the API to be called with the NEW, refreshed token
    #   expect(GoogleApiMock, :list_events, fn "new-refreshed-token", _, _, _ ->
    #     # Just sync one event for this test
    #     {:ok, %{"items" => [@mock_google_events |> Enum.at(0)]}}
    #   end)

    #   # --- 2. EXECUTION ---
    #   assert {:ok, :sync_complete} = CalendarSyncronizer.sync_events_for_user(user)

    #   # --- 3. ASSERTION ---
    #   # Verify that one event was synced to the DB after the token refresh
    #   assert Repo.aggregate(CalendarEvent, :count, :id) == 1
    #   assert Repo.get_by!(CalendarEvent, google_event_id: "zoom-event-123")
    # end
  end
end

defmodule SocialScribe.AccountsTest do
  use SocialScribe.DataCase

  alias SocialScribe.Accounts

  import SocialScribe.AccountsFixtures
  alias SocialScribe.Accounts.{User, UserToken, UserCredential}

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(-1)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Accounts.register_user(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = user_fixture()
      {:error, changeset} = Accounts.register_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users with a hashed password" do
      email = unique_user_email()
      {:ok, user} = Accounts.register_user(valid_user_attributes(email: email))
      assert user.email == email
      assert is_binary(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end
  end

  describe "change_user_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_registration(%User{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_user_email()
      password = valid_user_password()

      changeset =
        Accounts.change_user_registration(
          %User{},
          valid_user_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "delete_user_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_user_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end

  describe "user_credentials" do
    alias SocialScribe.Accounts.UserCredential

    import SocialScribe.AccountsFixtures

    @invalid_attrs %{token: nil, uid: nil, provider: nil, refresh_token: nil, expires_at: nil}

    test "list_user_credentials/0 returns all user_credentials" do
      user_credential = user_credential_fixture()
      assert Accounts.list_user_credentials() == [user_credential]
    end

    test "get_user_credential!/1 returns the user_credential with given id" do
      user_credential = user_credential_fixture()
      assert Accounts.get_user_credential!(user_credential.id) == user_credential
    end

    test "get_user_credential/3 returns the user_credential with given user, provider, and uid" do
      user = user_fixture()
      user_credential = user_credential_fixture(%{user_id: user.id})

      assert Accounts.get_user_credential(user, user_credential.provider, user_credential.uid) ==
               user_credential
    end

    test "create_user_credential/1 with valid data creates a user_credential" do
      existing_user = user_fixture()

      valid_attrs = %{
        user_id: existing_user.id,
        token: "some token",
        uid: "some uid",
        provider: "some provider",
        refresh_token: "some refresh_token",
        expires_at: ~U[2025-05-23 15:01:00Z]
      }

      assert {:ok, %UserCredential{} = user_credential} =
               Accounts.create_user_credential(valid_attrs)

      assert user_credential.token == "some token"
      assert user_credential.uid == "some uid"
      assert user_credential.provider == "some provider"
      assert user_credential.refresh_token == "some refresh_token"
      assert user_credential.expires_at == ~U[2025-05-23 15:01:00Z]
    end

    test "create_user_credential/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user_credential(@invalid_attrs)
    end

    test "update_user_credential/2 with valid data updates the user_credential" do
      user_credential = user_credential_fixture()

      update_attrs = %{
        token: "some updated token",
        uid: "some updated uid",
        provider: "some updated provider",
        refresh_token: "some updated refresh_token",
        expires_at: ~U[2025-05-24 15:01:00Z]
      }

      assert {:ok, %UserCredential{} = user_credential} =
               Accounts.update_user_credential(user_credential, update_attrs)

      assert user_credential.token == "some updated token"
      assert user_credential.uid == "some updated uid"
      assert user_credential.provider == "some updated provider"
      assert user_credential.refresh_token == "some updated refresh_token"
      assert user_credential.expires_at == ~U[2025-05-24 15:01:00Z]
    end

    test "update_user_credential/2 with invalid data returns error changeset" do
      user_credential = user_credential_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Accounts.update_user_credential(user_credential, @invalid_attrs)

      assert user_credential == Accounts.get_user_credential!(user_credential.id)
    end

    test "delete_user_credential/1 deletes the user_credential" do
      user_credential = user_credential_fixture()
      assert {:ok, %UserCredential{}} = Accounts.delete_user_credential(user_credential)

      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user_credential!(user_credential.id)
      end
    end

    test "change_user_credential/1 returns a user_credential changeset" do
      user_credential = user_credential_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user_credential(user_credential)
    end
  end

  describe "find_or_create_user_from_google/2" do
    @tag :google_auth
    test "when the user has previously logged in with Google, it finds the existing user" do
      google_profile = %{
        sub: "google-uid-12345",
        email: "existing@example.com",
        name: "Existing User"
      }

      existing_user = user_fixture(%{email: google_profile.email})

      _user_credential =
        user_credential_fixture(%{
          uid: google_profile.sub,
          provider: "google",
          user_id: existing_user.id
        })

      # Create a mock token data map.
      token_data = %{
        access_token: "test-token",
        refresh_token: "test-refresh",
        refresh_token_expires_in: 3600
      }

      {:ok, found_user} = Accounts.find_or_create_user_from_google(google_profile, token_data)

      assert found_user.id == existing_user.id
      assert Repo.aggregate(Accounts.User, :count, :id) == 1
    end

    @tag :google_auth
    test "when a user with the same email exists, it links the Google account to them" do
      google_profile = %{sub: "google-uid-new", email: "existing@example.com"}

      existing_user = user_fixture(%{email: google_profile.email})

      token_data = %{
        access_token: "test-token-2",
        refresh_token: "test-refresh-2",
        refresh_token_expires_in: 3600
      }

      {:ok, found_user} = Accounts.find_or_create_user_from_google(google_profile, token_data)

      assert found_user.id == existing_user.id
      credential = Repo.get_by!(UserCredential, uid: "google-uid-new")
      assert credential.user_id == existing_user.id
      assert Repo.aggregate(Accounts.User, :count, :id) == 1
    end

    @tag :google_auth
    test "when no user exists, it creates a new user and credential" do
      google_profile = %{sub: "google-uid-fresh", email: "new@example.com"}

      token_data = %{
        access_token: "test-token-3",
        refresh_token: "test-refresh-3",
        refresh_token_expires_in: 3600
      }

      assert Repo.aggregate(Accounts.User, :count, :id) == 0

      {:ok, new_user} = Accounts.find_or_create_user_from_google(google_profile, token_data)

      assert new_user.email == "new@example.com"
      assert Repo.aggregate(Accounts.User, :count, :id) == 1
      credential = Repo.get_by!(UserCredential, uid: "google-uid-fresh")
      assert credential.user_id == new_user.id
    end
  end
end

defmodule SocialScribe.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias SocialScribe.Repo

  alias SocialScribe.Accounts.{User, UserToken, UserCredential}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## User Credentials

  @doc """
  Returns the list of user_credentials.

  ## Examples

      iex> list_user_credentials()
      [%UserCredential{}, ...]

  """
  def list_user_credentials do
    Repo.all(UserCredential)
  end

  @doc """
  Gets a single user_credential.

  Raises `Ecto.NoResultsError` if the User credential does not exist.

  ## Examples

      iex> get_user_credential!(123)
      %UserCredential{}

      iex> get_user_credential!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_credential!(id), do: Repo.get!(UserCredential, id)

  @doc """
  Gets a user credential by user, provider, and uid.

  ## Examples

      iex> get_user_credential(user, "google", "google-uid-12345")
      %UserCredential{}

      iex> get_user_credential(user, "google", "google-uid-12345")
      nil
  """
  def get_user_credential(user, provider, uid) do
    Repo.get_by(UserCredential, user_id: user.id, provider: provider, uid: uid)
  end

  @doc """
  Creates a user_credential.

  ## Examples

      iex> create_user_credential(%{field: value})
      {:ok, %UserCredential{}}

      iex> create_user_credential(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_credential(attrs \\ %{}) do
    %UserCredential{}
    |> UserCredential.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user_credential.

  ## Examples

      iex> update_user_credential(user_credential, %{field: new_value})
      {:ok, %UserCredential{}}

      iex> update_user_credential(user_credential, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_credential(%UserCredential{} = user_credential, attrs) do
    user_credential
    |> UserCredential.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user_credential.

  ## Examples

      iex> delete_user_credential(user_credential)
      {:ok, %UserCredential{}}

      iex> delete_user_credential(user_credential)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_credential(%UserCredential{} = user_credential) do
    Repo.delete(user_credential)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_credential changes.

  ## Examples

      iex> change_user_credential(user_credential)
      %Ecto.Changeset{data: %UserCredential{}}

  """
  def change_user_credential(%UserCredential{} = user_credential, attrs \\ %{}) do
    UserCredential.changeset(user_credential, attrs)
  end

  ## Google Auth

  def find_or_create_user_from_google(profile, token_data) do
    Repo.transaction(fn ->
      user = find_or_create_user(profile)

      find_or_create_user_credential(user, profile, token_data)

      user
    end)
  end

  defp find_or_create_user(profile) do
    case get_user_by_google_uid(profile.sub) do
      %User{} = user ->
        user

      nil ->
        case get_user_by_email(profile.email) do
          %User{} = user ->
            user

          nil ->
            %User{}
            |> User.oauth_registration_changeset(%{
              email: profile.email
            })
            |> Repo.insert!()
        end
    end
  end

  defp find_or_create_user_credential(user, profile, token_data) do
    case get_user_credential(user, "google", profile.sub) do
      nil ->
        create_user_credential(%{
          user_id: user.id,
          provider: "google",
          uid: profile.sub,
          token: token_data.access_token,
          refresh_token: token_data.refresh_token,
          expires_at:
            DateTime.add(DateTime.utc_now(), token_data.refresh_token_expires_in, :second)
        })

      %UserCredential{} = credential ->
        update_user_credential(credential, %{
          token: token_data.access_token,
          refresh_token: token_data.refresh_token,
          expires_at:
            DateTime.add(DateTime.utc_now(), token_data.refresh_token_expires_in, :second)
        })
    end
  end

  defp get_user_by_google_uid(uid) do
    from(c in UserCredential,
      where: c.provider == "google" and c.uid == ^uid,
      join: u in assoc(c, :user),
      select: u
    )
    |> Repo.one()
  end
end

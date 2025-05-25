defmodule SocialScribe.Bots do
  @moduledoc """
  The Bots context.
  """

  import Ecto.Query, warn: false
  alias SocialScribe.Repo

  alias SocialScribe.Bots.RecallBot
  alias SocialScribe.RecallApi

  @doc """
  Returns the list of recall_bots.

  ## Examples

      iex> list_recall_bots()
      [%RecallBot{}, ...]

  """
  def list_recall_bots do
    Repo.all(RecallBot)
  end

  @doc """
  Gets a single recall_bot.

  Raises `Ecto.NoResultsError` if the Recall bot does not exist.

  ## Examples

      iex> get_recall_bot!(123)
      %RecallBot{}

      iex> get_recall_bot!(456)
      ** (Ecto.NoResultsError)

  """
  def get_recall_bot!(id), do: Repo.get!(RecallBot, id)

  @doc """
  Creates a recall_bot.

  ## Examples

      iex> create_recall_bot(%{field: value})
      {:ok, %RecallBot{}}

      iex> create_recall_bot(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_recall_bot(attrs \\ %{}) do
    %RecallBot{}
    |> RecallBot.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a recall_bot.

  ## Examples

      iex> update_recall_bot(recall_bot, %{field: new_value})
      {:ok, %RecallBot{}}

      iex> update_recall_bot(recall_bot, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_recall_bot(%RecallBot{} = recall_bot, attrs) do
    recall_bot
    |> RecallBot.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a recall_bot.

  ## Examples

      iex> delete_recall_bot(recall_bot)
      {:ok, %RecallBot{}}

      iex> delete_recall_bot(recall_bot)
      {:error, %Ecto.Changeset{}}

  """
  def delete_recall_bot(%RecallBot{} = recall_bot) do
    Repo.delete(recall_bot)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking recall_bot changes.

  ## Examples

      iex> change_recall_bot(recall_bot)
      %Ecto.Changeset{data: %RecallBot{}}

  """
  def change_recall_bot(%RecallBot{} = recall_bot, attrs \\ %{}) do
    RecallBot.changeset(recall_bot, attrs)
  end

  # --- Orchestration Functions ---

  @doc """
  Orchestrates creating a bot via the API and saving it to the database.
  """
  def create_and_dispatch_bot(user, calendar_event) do
    with {:ok, %{body: api_response}} <-
           RecallApi.create_bot(
             calendar_event.hangout_link,
             DateTime.add(calendar_event.start_time, -2, :minute)
           ) do
      create_recall_bot(%{
        user_id: user.id,
        calendar_event_id: calendar_event.id,
        recall_bot_id: api_response.id,
        meeting_url: calendar_event.hangout_link,
        status: api_response.status_changes |> List.first() |> Map.get(:code)
      })
    else
      {:error, reason} -> {:error, {:api_error, reason}}
    end
  end

  @doc """
  Orchestrates deleting a bot via the API and removing it from the database.
  """
  def cancel_and_delete_bot(calendar_event) do
    case Repo.get_by(RecallBot, calendar_event_id: calendar_event.id) do
      nil ->
        {:ok, :no_bot_to_cancel}

      %RecallBot{} = bot ->
        case RecallApi.delete_bot(bot.recall_bot_id) do
          {:ok, %{status: 404}} -> delete_recall_bot(bot)
          {:ok, _} -> delete_recall_bot(bot)
          {:error, reason} -> {:error, {:api_error, reason}}
        end
    end
  end

  @doc """
  Orchestrates updating a bot's schedule via the API and saving it to the database.
  """
  def update_bot_schedule(bot, calendar_event) do
    with {:ok, %{body: api_response}} <-
           RecallApi.update_bot(
             bot.recall_bot_id,
             calendar_event.hangout_link,
             DateTime.add(calendar_event.start_time, -2, :minute)
           ) do
      update_recall_bot(bot, %{
        status: api_response.status_changes |> List.first() |> Map.get(:code)
      })
    end
  end
end

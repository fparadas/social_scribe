defmodule SocialScribe.Automations do
  @moduledoc """
  The Automations context.
  """

  import Ecto.Query, warn: false
  alias SocialScribe.Repo

  alias SocialScribe.Automations.Automation

  @doc """
  Returns the list of automations for a user.
  """
  def list_active_user_automations(user_id) do
    from(a in Automation, where: a.user_id == ^user_id and a.is_active == true, order_by: a.name)
    |> Repo.all()
  end

  @doc """
  Returns the list of automations.

  ## Examples

      iex> list_automations()
      [%Automation{}, ...]

  """
  def list_automations do
    Repo.all(Automation)
  end

  @doc """
  Gets a single automation.

  Raises `Ecto.NoResultsError` if the Automation does not exist.

  ## Examples

      iex> get_automation!(123)
      %Automation{}

      iex> get_automation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_automation!(id), do: Repo.get!(Automation, id)

  @doc """
  Creates a automation.

  ## Examples

      iex> create_automation(%{field: value})
      {:ok, %Automation{}}

      iex> create_automation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_automation(attrs \\ %{}) do
    %Automation{}
    |> Automation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a automation.

  ## Examples

      iex> update_automation(automation, %{field: new_value})
      {:ok, %Automation{}}

      iex> update_automation(automation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_automation(%Automation{} = automation, attrs) do
    automation
    |> Automation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a automation.

  ## Examples

      iex> delete_automation(automation)
      {:ok, %Automation{}}

      iex> delete_automation(automation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_automation(%Automation{} = automation) do
    Repo.delete(automation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking automation changes.

  ## Examples

      iex> change_automation(automation)
      %Ecto.Changeset{data: %Automation{}}

  """
  def change_automation(%Automation{} = automation, attrs \\ %{}) do
    Automation.changeset(automation, attrs)
  end

  @doc """
  Generates a prompt for an automation.
  """
  def generate_prompt_for_automation(%Automation{} = automation) do
    """
    #{automation.description}

    ### Example:
    #{automation.example}
    """
  end

  alias SocialScribe.Automations.AutomationResult

  @doc """
  Returns the list of automation_results.

  ## Examples

      iex> list_automation_results()
      [%AutomationResult{}, ...]

  """
  def list_automation_results do
    Repo.all(AutomationResult)
  end

  @doc """
  Returns the list of automation_results for a meeting.
  """
  def list_automation_results_for_meeting(meeting_id) do
    from(ar in AutomationResult, where: ar.meeting_id == ^meeting_id)
    |> Repo.all()
    |> Repo.preload([:automation])
  end

  @doc """
  Gets a single automation_result.

  Raises `Ecto.NoResultsError` if the Automation result does not exist.

  ## Examples

      iex> get_automation_result!(123)
      %AutomationResult{}

      iex> get_automation_result!(456)
      ** (Ecto.NoResultsError)

  """
  def get_automation_result!(id), do: Repo.get!(AutomationResult, id)

  @doc """
  Creates a automation_result.

  ## Examples

      iex> create_automation_result(%{field: value})
      {:ok, %AutomationResult{}}

      iex> create_automation_result(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_automation_result(attrs \\ %{}) do
    %AutomationResult{}
    |> AutomationResult.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a automation_result.

  ## Examples

      iex> update_automation_result(automation_result, %{field: new_value})
      {:ok, %AutomationResult{}}

      iex> update_automation_result(automation_result, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_automation_result(%AutomationResult{} = automation_result, attrs) do
    automation_result
    |> AutomationResult.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a automation_result.

  ## Examples

      iex> delete_automation_result(automation_result)
      {:ok, %AutomationResult{}}

      iex> delete_automation_result(automation_result)
      {:error, %Ecto.Changeset{}}

  """
  def delete_automation_result(%AutomationResult{} = automation_result) do
    Repo.delete(automation_result)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking automation_result changes.

  ## Examples

      iex> change_automation_result(automation_result)
      %Ecto.Changeset{data: %AutomationResult{}}

  """
  def change_automation_result(%AutomationResult{} = automation_result, attrs \\ %{}) do
    AutomationResult.changeset(automation_result, attrs)
  end
end

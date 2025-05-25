defmodule SocialScribe.Automations do
  @moduledoc """
  The Automations context.
  """

  import Ecto.Query, warn: false
  alias SocialScribe.Repo

  alias SocialScribe.Automations.Automation

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
end

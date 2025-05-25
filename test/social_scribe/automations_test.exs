defmodule SocialScribe.AutomationsTest do
  use SocialScribe.DataCase

  alias SocialScribe.Automations
  import SocialScribe.AccountsFixtures

  describe "automations" do
    alias SocialScribe.Automations.Automation

    import SocialScribe.AutomationsFixtures

    @invalid_attrs %{name: nil, description: nil, platform: nil, example: nil, is_active: nil}

    test "list_automations/0 returns all automations" do
      automation = automation_fixture()
      assert Automations.list_automations() == [automation]
    end

    test "get_automation!/1 returns the automation with given id" do
      automation = automation_fixture()
      assert Automations.get_automation!(automation.id) == automation
    end

    test "create_automation/1 with valid data creates a automation" do
      user = user_fixture()

      valid_attrs = %{
        name: "some name",
        description: "some description",
        platform: "some platform",
        example: "some example",
        is_active: true,
        user_id: user.id
      }

      assert {:ok, %Automation{} = automation} = Automations.create_automation(valid_attrs)
      assert automation.name == "some name"
      assert automation.description == "some description"
      assert automation.platform == "some platform"
      assert automation.example == "some example"
      assert automation.is_active == true
    end

    test "create_automation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Automations.create_automation(@invalid_attrs)
    end

    test "update_automation/2 with valid data updates the automation" do
      automation = automation_fixture()

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        platform: "some updated platform",
        example: "some updated example",
        is_active: false
      }

      assert {:ok, %Automation{} = automation} =
               Automations.update_automation(automation, update_attrs)

      assert automation.name == "some updated name"
      assert automation.description == "some updated description"
      assert automation.platform == "some updated platform"
      assert automation.example == "some updated example"
      assert automation.is_active == false
    end

    test "update_automation/2 with invalid data returns error changeset" do
      automation = automation_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Automations.update_automation(automation, @invalid_attrs)

      assert automation == Automations.get_automation!(automation.id)
    end

    test "delete_automation/1 deletes the automation" do
      automation = automation_fixture()
      assert {:ok, %Automation{}} = Automations.delete_automation(automation)
      assert_raise Ecto.NoResultsError, fn -> Automations.get_automation!(automation.id) end
    end

    test "change_automation/1 returns a automation changeset" do
      automation = automation_fixture()
      assert %Ecto.Changeset{} = Automations.change_automation(automation)
    end
  end
end

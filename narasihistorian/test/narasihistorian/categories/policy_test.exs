defmodule Narasihistorian.Categories.PolicyTest do
  use ExUnit.Case, async: true

  alias Narasihistorian.Accounts.User
  alias Narasihistorian.Categories.Category
  alias Narasihistorian.Categories.Policy

  defp admin, do: %User{id: 1, role: :admin}
  defp regular_user, do: %User{id: 2, role: :user}
  defp category, do: %Category{id: 1, category_name: "History"}

  # --- can_create?/1 ---

  describe "can_create?/1" do
    test "returns true for admin" do
      assert Policy.can_create?(admin()) == true
    end

    test "returns false for regular user" do
      assert Policy.can_create?(regular_user()) == false
    end

    test "returns false for nil / unauthenticated" do
      assert Policy.can_create?(nil) == false
    end
  end

  # --- can_edit?/2 ---

  describe "can_edit?/2" do
    test "admin can edit any category" do
      assert Policy.can_edit?(admin(), category()) == true
    end

    test "regular user cannot edit a category" do
      assert Policy.can_edit?(regular_user(), category()) == false
    end

    test "nil user cannot edit a category" do
      assert Policy.can_edit?(nil, category()) == false
    end
  end

  # --- can_delete?/2 ---

  describe "can_delete?/2" do
    test "admin can delete any category" do
      assert Policy.can_delete?(admin(), category()) == true
    end

    test "regular user cannot delete a category" do
      assert Policy.can_delete?(regular_user(), category()) == false
    end

    test "nil user cannot delete a category" do
      assert Policy.can_delete?(nil, category()) == false
    end
  end
end

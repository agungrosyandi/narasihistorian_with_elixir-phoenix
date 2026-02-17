defmodule Narasihistorian.Articles.PolicyTest do
  use ExUnit.Case, async: true

  alias Narasihistorian.Accounts.User
  alias Narasihistorian.Articles.Article
  alias Narasihistorian.Articles.Policy

  # Build structs without hitting the DB at all

  defp admin, do: %User{id: 1, role: :admin}
  defp regular_user(id \\ 2), do: %User{id: id, role: :user}
  defp article(owner_id \\ 2), do: %Article{id: 10, user_id: owner_id}

  # --- can_list_all?/1 ---

  describe "can_list_all?/1" do
    test "returns true for admin" do
      assert Policy.can_list_all?(admin()) == true
    end

    test "returns false for regular user" do
      assert Policy.can_list_all?(regular_user()) == false
    end

    test "returns false for nil / unauthenticated" do
      assert Policy.can_list_all?(nil) == false
    end
  end

  # --- can_create?/1 ---

  describe "can_create?/1" do
    test "returns true for any authenticated user" do
      assert Policy.can_create?(regular_user()) == true
    end

    test "returns true for admin" do
      assert Policy.can_create?(admin()) == true
    end

    test "returns false for nil / unauthenticated" do
      assert Policy.can_create?(nil) == false
    end
  end

  # --- can_view?/2 ---

  describe "can_view?/2" do
    test "admin can view any article" do
      assert Policy.can_view?(admin(), article(99)) == true
    end

    test "owner can view their own article" do
      user = regular_user(5)
      assert Policy.can_view?(user, article(5)) == true
    end

    test "non-owner cannot view someone else's article" do
      user = regular_user(5)
      assert Policy.can_view?(user, article(99)) == false
    end

    test "nil user cannot view any article" do
      assert Policy.can_view?(nil, article()) == false
    end
  end

  # --- can_edit?/2 ---

  describe "can_edit?/2" do
    test "admin can edit any article" do
      assert Policy.can_edit?(admin(), article(99)) == true
    end

    test "owner can edit their own article" do
      user = regular_user(5)
      assert Policy.can_edit?(user, article(5)) == true
    end

    test "non-owner cannot edit someone else's article" do
      user = regular_user(5)
      assert Policy.can_edit?(user, article(99)) == false
    end

    test "nil user cannot edit any article" do
      assert Policy.can_edit?(nil, article()) == false
    end
  end

  # --- can_delete?/2 ---

  describe "can_delete?/2" do
    test "admin can delete any article" do
      assert Policy.can_delete?(admin(), article(99)) == true
    end

    test "owner can delete their own article" do
      user = regular_user(5)
      assert Policy.can_delete?(user, article(5)) == true
    end

    test "non-owner cannot delete someone else's article" do
      user = regular_user(5)
      assert Policy.can_delete?(user, article(99)) == false
    end

    test "nil user cannot delete any article" do
      assert Policy.can_delete?(nil, article()) == false
    end
  end
end

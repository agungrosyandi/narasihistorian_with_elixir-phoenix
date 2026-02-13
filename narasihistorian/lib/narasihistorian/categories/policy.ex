defmodule Narasihistorian.Categories.Policy do
  @moduledoc """
  Authorization policy for categories.
  Defines what users can do with categories.
  """

  alias Narasihistorian.Accounts.User
  alias Narasihistorian.Categories.Category

  @doc """
  Can user create categories?
  Only admins can create categories.
  """

  def can_create?(%User{role: :admin}), do: true
  def can_create?(_user), do: false

  @doc """
  Can user edit this category?
  Only admins can edit categories.
  """

  def can_edit?(%User{role: :admin}, %Category{}), do: true
  def can_edit?(_user, _category), do: false

  @doc """
  Can user delete this category?
  Only admins can delete categories.
  """

  def can_delete?(%User{role: :admin}, %Category{}), do: true
  def can_delete?(_user, _category), do: false
end

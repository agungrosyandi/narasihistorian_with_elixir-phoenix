defmodule Narasihistorian.CategoriesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Narasihistorian.Categories` context.
  """

  @doc """
  Generate a unique category category_name.
  """
  def unique_category_category_name, do: "some category_name#{System.unique_integer([:positive])}"

  @doc """
  Generate a unique category slug.
  """
  def unique_category_slug, do: "some slug#{System.unique_integer([:positive])}"

  @doc """
  Generate a category.
  """
  def category_fixture(attrs \\ %{}) do
    {:ok, category} =
      attrs
      |> Enum.into(%{
        category_name: unique_category_category_name(),
        slug: unique_category_slug()
      })
      |> Narasihistorian.Categories.create_category()

    category
  end
end

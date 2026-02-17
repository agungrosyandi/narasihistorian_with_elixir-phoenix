defmodule Narasihistorian.CategoriesFixtures do
  import Narasihistorian.AccountsFixtures

  def category_fixture(attrs \\ %{}, user \\ nil) do
    user = user || user_fixture()

    {:ok, category} =
      attrs
      |> Enum.into(%{
        category_name: "category #{System.unique_integer([:positive])}",
        slug: "category-slug-#{System.unique_integer([:positive])}"
      })
      |> Narasihistorian.Categories.create_category(user)

    category
  end
end

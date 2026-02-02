defmodule Narasihistorian.Categories do
  @moduledoc """
  The Categories context.
  """

  import Ecto.Query, warn: false
  alias Narasihistorian.Repo

  alias Narasihistorian.Categories.Category

  def list_categories, do: Repo.all(Category)

  def get_category!(id), do: Repo.get!(Category, id)

  def get_category_with_articles!(id) do
    get_category!(id)
    |> Repo.preload(:articles)
  end

  def category_name_and_ids do
    query =
      from c in Category,
        order_by: :category_name,
        select: {c.category_name, c.id}

    Repo.all(query)
  end

  def category_name_and_slugs do
    query =
      from c in Category,
        order_by: :category_name,
        select: {c.category_name, c.slug}

    Repo.all(query)
  end

  def create_category(attrs) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  def delete_category(%Category{} = category), do: Repo.delete(category)

  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end
end

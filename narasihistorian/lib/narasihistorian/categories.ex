defmodule Narasihistorian.Categories do
  @moduledoc """
  The Categories context.
  """

  import Ecto.Query, warn: false
  alias Narasihistorian.Categories.Policy
  alias Narasihistorian.Repo

  alias Narasihistorian.Categories.Category
  alias Narasihistorian.Uploader

  # ============================================================================
  # LIST CATEGORY
  # ============================================================================

  # def list_categories, do: Repo.all(Category)

  def list_categories(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 10)
    offset = (page - 1) * per_page

    Category
    |> order_by([c], c.category_name)
    |> limit(^per_page)
    |> offset(^offset)
    |> Repo.all()
  end

  # ============================================================================
  # GET CATEGORY
  # ============================================================================

  def get_category!(id), do: Repo.get!(Category, id)

  def get_category_with_articles!(id) do
    get_category!(id)
    |> Repo.preload(:articles)
  end

  # ============================================================================
  # CATEGORY BY NAME AND ID
  # ============================================================================

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

  # ============================================================================
  # CREATE CATEGORY
  # ============================================================================

  def create_category(attrs, user) do
    %Category{}
    |> Category.creation_changeset(attrs, user)
    |> Repo.insert()
  end

  # ============================================================================
  # UPDATE CATEGORY
  # ============================================================================

  def update_category(%Category{} = category, attrs, current_user) do
    if Policy.can_edit?(current_user, category) do
      category
      |> Category.changeset(attrs)
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end

  # ============================================================================
  # DELETE CATEGORY
  # ============================================================================

  def delete_category(%Category{} = category) do
    category = Repo.preload(category, :articles)

    case category.articles do
      [] ->
        case Repo.delete(category) do
          {:ok, deleted_category} ->
            if deleted_category.image_category do
              delete_category_image(deleted_category.image_category)
            end

            {:ok, deleted_category}

          {:error, changeset} ->
            {:error, changeset}
        end

      _articles ->
        {:error, :has_articles}
    end
  end

  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  # ============================================================================
  # Private helper to delete image from R2
  # ============================================================================

  defp delete_category_image(image_url) do
    case Uploader.extract_key(image_url) do
      nil ->
        :ok

      key ->
        # Use Task.start to avoid blocking
        Task.start(fn -> Uploader.delete_file(key) end)
        :ok
    end
  end
end

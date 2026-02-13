defmodule Narasihistorian.Tags do
  import Ecto.Query
  alias Narasihistorian.Repo
  alias Narasihistorian.Tags.Tag

  alias Narasihistorian.Articles.Article

  def list_tags, do: Repo.all(Tag)

  def get_tag!(id), do: Repo.get!(Tag, id)

  def get_or_create_tags(tag_names) when is_list(tag_names) do
    tag_names
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.map(&get_or_create_tag/1)
  end

  defp get_or_create_tag(name) do
    case Repo.get_by(Tag, name: name) do
      nil -> create_tag(%{name: name})
      tag -> {:ok, tag}
    end
  end

  def create_tag(attrs) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  def get_related_articles_by_tags(article_id, limit \\ 5) do
    from(a in Article,
      join: at in "articles_tags",
      on: at.article_id == a.id,
      join: at2 in "articles_tags",
      on: at2.tag_id == at.tag_id,
      where: at2.article_id == ^article_id and a.id != ^article_id,
      group_by: a.id,
      order_by: [desc: count(at.tag_id), desc: a.inserted_at],
      limit: ^limit,
      preload: [:category, :user, :tags],
      select: a
    )
    |> Repo.all()
  end

  # Add function to get tag by slug

  def get_tag_by_slug(slug) do
    Repo.get_by(Tag, slug: slug)
  end

  # Add function to get tag by name

  def get_tag_by_name(name) do
    Repo.get_by(Tag, name: name)
  end
end

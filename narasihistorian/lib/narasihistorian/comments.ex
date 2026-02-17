defmodule Narasihistorian.Comments do
  @moduledoc """
  The Comments context.
  """

  import Ecto.Query, warn: false

  alias Narasihistorian.Dashboard
  alias Narasihistorian.Accounts.User
  alias Narasihistorian.Repo

  alias Narasihistorian.Comments.Comment

  # ============================================================================
  # GET ALL AND COMMENT BY ID
  # ============================================================================

  def list_comments, do: Repo.all(Comment)

  def list_comments_paginated(article_id, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 5)
    offset = (page - 1) * per_page

    total_count =
      from(c in Comment, where: c.article_id == ^article_id)
      |> Repo.aggregate(:count, :id)

    comments =
      from(c in Comment,
        where: c.article_id == ^article_id,
        order_by: [desc: c.inserted_at],
        limit: ^per_page,
        offset: ^offset,
        preload: [:user]
      )
      |> Repo.all()

    %{
      comments: comments,
      total_count: total_count,
      has_more: offset + per_page < total_count
    }
  end

  def get_comment!(id), do: Repo.get!(Comment, id)

  # ============================================================================
  # CREATE COMMENT
  # ============================================================================

  def create_comment(attrs) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, _comment} = result ->
        Dashboard.notify_comment_created()
        result

      error ->
        error
    end
  end

  # ============================================================================
  # UPDATE COMMENT
  # ============================================================================

  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  # ============================================================================
  # DELETE COMMENT
  # ============================================================================

  def delete_comment(%Comment{} = comment, %User{} = user) do
    if can_delete?(comment, user) do
      Repo.delete(comment)
    else
      {:error, :unauthorized}
    end
  end

  def can_delete?(%Comment{user_id: user_id}, %User{id: id})
      when user_id == id,
      do: true

  def can_delete?(_, %User{role: :admin}), do: true

  def can_delete?(_, _), do: false

  def change_comment(%Comment{} = comment, attrs \\ %{}), do: Comment.changeset(comment, attrs)
end

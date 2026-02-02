defmodule Narasihistorian.Comments do
  @moduledoc """
  The Comments context.
  """

  import Ecto.Query, warn: false

  alias Narasihistorian.Dashboard
  alias Narasihistorian.Accounts.User
  alias Narasihistorian.Repo

  alias Narasihistorian.Comments.Comment

  # ALL LIST COMMENT

  def list_comments, do: Repo.all(Comment)

  def get_comment!(id), do: Repo.get!(Comment, id)

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

  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

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

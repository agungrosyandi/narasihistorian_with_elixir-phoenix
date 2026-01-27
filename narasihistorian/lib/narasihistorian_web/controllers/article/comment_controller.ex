defmodule NarasihistorianWeb.CommentController do
  use NarasihistorianWeb, :controller

  alias Narasihistorian.Comments

  # CREATE COMMENT

  def create(conn, %{"id" => article_id, "comment" => comment_params}) do
    comment_params =
      comment_params
      |> Map.put("article_id", article_id)
      |> Map.put("user_id", conn.assigns.current_user.id)

    case Comments.create_comment(comment_params) do
      {:ok, _comment} ->
        conn
        |> put_flash(:info, "Comment added")
        |> redirect(to: ~p"/articles/#{article_id}")

      {:error, changeset} ->
        article = Narasihistorian.Articles.get_articles!(article_id)

        conn
        |> assign(:article, article)
        |> assign(:comments, article.comments)
        |> assign(:form, Phoenix.Component.to_form(changeset, as: :comment))
        |> put_flash(:error, "Failed to add comment")
        |> redirect(to: ~p"/articles/#{article_id}")
    end
  end

  # DELETE COMMENT

  def delete(conn, %{"id" => article_id, "comment_id" => comment_id}) do
    user = conn.assigns.current_user
    comment = Comments.get_comment!(comment_id)

    case Comments.delete_comment(comment, user) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Komentar dihapus")
        |> redirect(to: ~p"/articles/#{article_id}")

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> put_flash(:error, "Anda tidak berhak menghapus komentar ini")
        |> redirect(to: ~p"/articles/#{article_id}")
    end
  end
end

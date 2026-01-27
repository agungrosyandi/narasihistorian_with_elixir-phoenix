defmodule Narasihistorian.CommentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Narasihistorian.Comments` context.
  """

  @doc """
  Generate a comment.
  """
  def comment_fixture(attrs \\ %{}) do
    {:ok, comment} =
      attrs
      |> Enum.into(%{
        comment: "some comment"
      })
      |> Narasihistorian.Comments.create_comment()

    comment
  end
end

defmodule NarasihistorianWeb.ArticleHTML do
  use NarasihistorianWeb, :html

  # TRUNCATE TEXT / DESCRIPTION

  def truncate(text, length) when is_binary(text) do
    if String.length(text) > length do
      String.slice(text, 0, length) <> "..."
    else
      text
    end
  end

  def truncate(nil, _length), do: ""

  def reading_time(text) when is_binary(text) do
    word_count = text |> String.split() |> length()

    # Average reading speed: 200 words per minute

    max(1, div(word_count, 200))
  end

  def reading_time(nil), do: 1

  embed_templates "article_html/*"
end

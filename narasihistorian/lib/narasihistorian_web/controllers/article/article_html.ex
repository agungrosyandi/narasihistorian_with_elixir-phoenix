defmodule NarasihistorianWeb.ArticleHTML do
  use NarasihistorianWeb, :html

  import NarasihistorianWeb.CustomComponents

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

  # QUILL RICH TEXT EDITOR  -------------------------------------------

  def quill_plain_text(nil), do: ""

  def quill_plain_text(html) do
    html
    |> String.replace(~r/<br\s*\/?>/i, " ")
    |> String.replace(~r/<\/p>/i, " ")
    |> String.replace(~r/<[^>]*>/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  def safe_quill_html(nil), do: ""

  def safe_quill_html(html) do
    HtmlSanitizeEx.basic_html(html)
  end

  embed_templates "article_html/*"
end

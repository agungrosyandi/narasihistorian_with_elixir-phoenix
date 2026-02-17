defmodule NarasihistorianWeb.ArticleHTML do
  use NarasihistorianWeb, :html

  # ============================================================================
  # TRUNCATE TEXT / DESCRIPTION
  # ============================================================================

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

    max(1, div(word_count, 200))
  end

  def reading_time(nil), do: 1

  # ============================================================================
  # TIME FORMAT
  # ============================================================================

  def time_ago_short(datetime) do
    now = DateTime.utc_now()

    datetime =
      case datetime do
        %NaiveDateTime{} ->
          DateTime.from_naive!(datetime, "Etc/UTC")

        %DateTime{} ->
          datetime
      end

    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 10 ->
        "Just now"

      diff < 60 ->
        "#{diff} detik yang lalu"

      diff < 3600 ->
        minutes = div(diff, 60)
        "#{minutes} menit yang lalu"

      diff < 86_400 ->
        hours = div(diff, 3600)
        "#{hours} jam yang lalu"

      diff < 604_800 ->
        days = div(diff, 86_400)
        "#{days} hari yang lalu"

      diff < 2_592_000 ->
        weeks = div(diff, 604_800)
        "#{weeks} minggu yang lalu"

      diff < 31_536_000 ->
        months = div(diff, 2_592_000)
        "#{months} bulan yang lalu"

      true ->
        years = div(diff, 31_536_000)
        "#{years} tahun yang lalu"
    end
  end

  # ============================================================================
  # QUILL RICH TEXT EDITOR
  # ============================================================================

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

  def safe_quill_html(html), do: HtmlSanitizeEx.basic_html(html)

  # ============================================================================
  # PAGINATION TAG
  # ============================================================================

  def pagination_range(current_page, total_pages) do
    cond do
      total_pages <= 7 ->
        1..total_pages

      current_page <= 4 ->
        1..7

      current_page >= total_pages - 3 ->
        (total_pages - 6)..total_pages

      true ->
        (current_page - 3)..(current_page + 3)
    end
  end

  embed_templates "article_html/*"
end

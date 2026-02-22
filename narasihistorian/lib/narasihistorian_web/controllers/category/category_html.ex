defmodule NarasihistorianWeb.CategoryHTML do
  use NarasihistorianWeb, :html

  import NarasihistorianWeb.CustomComponents,
    only: [
      truncate: 2,
      quill_plain_text: 1,
      load_more: 1,
      article_card: 1
    ]

  embed_templates "category_html/*"
end

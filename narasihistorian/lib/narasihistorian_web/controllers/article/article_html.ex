defmodule NarasihistorianWeb.ArticleHTML do
  use NarasihistorianWeb, :html

  import NarasihistorianWeb.CustomComponents,
    only: [
      safe_quill_html: 1,
      time_ago_short: 1,
      reading_time: 1,
      article_card: 1,
      load_more: 1,
      footer_home_public_page: 1,
      section_header: 1,
      card_swiper_carousel: 1,
      card_swiper_carousel_big: 1
    ]

  embed_templates "article_html/*"
end

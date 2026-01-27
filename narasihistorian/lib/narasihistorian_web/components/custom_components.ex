defmodule NarasihistorianWeb.CustomComponents do
  use NarasihistorianWeb, :html

  alias NarasihistorianWeb.ArticleHTML

  # HOME FOOTER --------------------------------------------------------------

  attr :class, :string, default: nil

  def footer_description(assigns) do
    ~H"""
    <footer class="relative gap-2 flex flex-col justify-between items-center py-10">
      <div class="relative flex flex-col justify-between items-center md:flex-row md:gap-10">
        <div class="w-[100%] flex-1">
          <img
            class="relative h-[full] w-full object-cover"
            src="/images/closng-background-cover.jpg"
            alt="My Image"
          />
        </div>

        <div class="py-10 gap-5 flex-1 flex flex-col  justify-center items-center md:px-5">
          <div>
            <span class="text-[#ffffffe0] font-bold text-xl">Tentang Narasi</span>
            <span class="text-[#fedf16e0] font-bold text-xl">Historian</span>
          </div>
          <p class="text-center text-base-content/60">
            Narasihistorian merupakan media konten yang berfokus pada sejarah
            peradaban global dengan visualisasi yangyang simple dan interaktif
            baik itu berupa konten artikel ataupun video infografik.
          </p>
        </div>
      </div>

      <div class="flex flex-row gap-5 justify-between w-full items-center">
        <small class="text-[#ffffffe0] font-bold text-xs">
          <.icon name="hero-minus-circle" class="w-4 h-4 mb-1 mr-1" /> 2024
        </small>
        <div class="flex items-center gap-5 text-xs">
          <.link
            href="mailto:agungrosyandi@gmail.com"
            class="text-white hover:text-[#fedf16e0] text-sm
             font-medium text-center transition-all duration-200"
          >
            <.icon name="hero-chevron-right" class="w-4 h-4 mb-1" /> Email
          </.link>

          <.link
            href="https://www.instagram.com/narasihistorian/"
            class="text-white hover:text-[#fedf16e0] text-sm
             font-medium text-center transition-all duration-200"
          >
            <.icon name="hero-chevron-right" class="w-4 h-4 mb-1" /> instagram
          </.link>

          <.link
            href="https://www.youtube.com/channel/UCNoUf4xYawhvK6dD94oDEDg"
            class="text-white hover:text-[#fedf16e0] text-sm
             font-medium text-center transition-all duration-200"
          >
            <.icon name="hero-chevron-right" class="w-4 h-4 mb-1" /> youtube
          </.link>
        </div>
      </div>
    </footer>
    """
  end

  # ARTICLE NOT FOUND --------------------------------------------------------------

  attr :class, :string, default: nil

  def content_article_not_found(assigns) do
    ~H"""
    <div class="max-w-2xl h-[15rem] mx-auto rounded-lg text-center shadow-xl flex gap-5 flex-col items-center justify-center">
      <p>
        Sorry, Artikel tidak ditemukan
        <.link patch={~p"/"} class="text-[#fedf16e0] font-bold">
          <.icon name="hero-arrows-right-left" class="w-4 h-4" />
          <span class="border-b pb-2 text-white hover:text-[#fedf16e0]">
            Kembali ke pencarian
          </span>
        </.link>
      </p>

      <.icon name="hero-no-symbol" class="w-10 h-10" />
    </div>
    """
  end

  # SEARCH QUERY --------------------------------------------------------------

  attr :class, :string, default: nil
  attr :search_query, :string, default: nil

  def search_query(assigns) do
    ~H"""
    <div class="flex flex-row w-full gap-2">
      <input
        type="text"
        name="q"
        value={@search_query}
        placeholder="Cari Artikel ......"
        class="input input-bordered w-full input-lg"
      />

      <button class="btn btn-square btn-primary btn-lg">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-6 w-6 "
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
          />
        </svg>
      </button>
    </div>
    """
  end

  # PAGINATION --------------------------------------------------------------

  attr :current_page, :integer, required: true
  attr :total_pages, :integer, required: true
  attr :search_query, :string, default: nil
  attr :selected_category, :string, default: nil
  attr :base_path, :string, default: "/articles"

  def pagination_home(assigns) do
    ~H"""
    <div class="flex justify-center mt-12">
      <div class="join">
        <%= if @current_page > 1 do %>
          <.link
            href={
              ~p"/articles?#{%{q: @search_query, category: @selected_category, page: @current_page - 1}}"
            }
            class="join-item btn"
          >
            «
          </.link>
        <% end %>

        <%= for page <- 1..@total_pages do %>
          <.link
            href={~p"/articles?#{%{q: @search_query, category: @selected_category, page: page}}"}
            class={"join-item btn #{if page == @current_page, do: "btn-active"}"}
          >
            {page}
          </.link>
        <% end %>

        <%= if @current_page < @total_pages do %>
          <.link
            href={
              ~p"/articles?#{%{q: @search_query, category: @selected_category, page: @current_page + 1}}"
            }
            class="join-item btn"
          >
            »
          </.link>
        <% end %>
      </div>
    </div>
    """
  end

  # filter --------------------------------------------------------------

  attr :category_options, :list, required: true
  attr :selected_category, :string, default: nil

  def category_select(assigns) do
    ~H"""
    <select name="category" class="select w-full" onchange="this.form.submit()">
      <option value="">All Categories</option>

      <%= for {category_name, category_slug} <- @category_options do %>
        <option value={category_slug} selected={category_slug == @selected_category}>
          {category_name}
        </option>
      <% end %>
    </select>
    """
  end

  # HEADER --------------------------------------------------------------

  attr :class, :string, default: nil

  def header_title(assigns) do
    ~H"""
    <div class="text-center mb-5">
      <h1 class="text-3xl font-bold mb-4 lg:text-4xl">
        Everything about <span class="text-[#fedf16e0]">history</span>
      </h1>
      <p class="text-base text-base-content/60">
        Explore the pivotal moments that shaped our world
      </p>
    </div>
    """
  end

  # ARTICLE FOUND --------------------------------------------------------------

  attr :articles, :list, required: true

  def article_found(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
      <%= for article <- @articles do %>
        <.link
          href={~p"/articles/#{article.id}"}
          class="group card bg-base-100 shadow-xl hover:shadow-2xl transition-all duration-300"
        >
          <div class="flex justify-center p-5 text-base font-bold shadow-xl">
            <.icon
              name="hero-arrow-trending-down"
              class="w-5 h-5 mb-1 mr-3 text-[#fedf16e0]"
            />
            {article.category.category_name}
          </div>

          <div class="flex flex-row md:flex-col">
            <figure class="relative overflow-hidden h-64">
              <img
                src={article.image}
                alt={article.article_name}
                class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
              />
            </figure>

            <div class="card-body">
              <h2 class="card-title group-hover:text-primary transition-colors">
                {article.article_name}
              </h2>

              <p class="text-base-content/70 line-clamp-3">
                {article.content
                |> ArticleHTML.quill_plain_text()
                |> String.slice(0, 120)}...
              </p>

              <div class="card-actions justify-between items-center mt-4">
                <span class="text-sm text-base-content/50">
                  {ArticleHTML.reading_time(article.content)} min read
                </span>

                <span class="text-white text-sm font-semibold group-hover:gap-2 flex items-center transition-all">
                  Read More
                  <.icon
                    name="hero-chevron-double-right"
                    class="w-5 h-5 ml-1 text-[#fedf16e0]"
                  />
                </span>
              </div>
            </div>
          </div>
        </.link>
      <% end %>
    </div>
    """
  end
end

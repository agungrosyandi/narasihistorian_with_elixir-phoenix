defmodule NarasihistorianWeb.Admin.CategoryLive.Show do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Categories

  # ============================================================================
  # MOUNT
  # ============================================================================

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Category")
     |> assign(:category, Categories.get_category_with_articles!(id))}
  end

  # ============================================================================
  # RENDER
  # ============================================================================

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="mb-14">
        <%!-------------------------%>
        <%!-- HEADER --%>
        <%!-------------------------%>

        <.header>
          <:actions>
            <div class="mb-5 flex flex-row gap-3 items-center">
              <.link navigate={~p"/admin/categories"} class="text-gray-400 hover:text-white">
                <.icon name="hero-arrow-left" class="w-6 h-6 mr-3" />
              </.link>
              <.button_custom
                variant="primary"
                navigate={~p"/admin/categories/#{@category}/edit?return_to=show"}
              >
                <.icon name="hero-pencil-square" /> Edit category
              </.button_custom>
            </div>
          </:actions>
        </.header>

        <%!-------------------------%>
        <%!-- MAIN UI --%>
        <%!-------------------------%>

        <div class="flex flex-col gap-5 lg:flex-row">
          <div class="w-[100%] flex-1">
            <img
              class="relative h-full w-full object-cover"
              src={@category.image_category}
              alt={@category.category_name}
            />
          </div>

          <div class="flex-[2_1_0%] shadow-2xl">
            <.list>
              <:item title="Kategori">
                <p class="text-gray-400 mt-3">{@category.category_name}</p>
              </:item>
              <:item title="Slug">
                <p class="text-gray-400 mt-3">{@category.slug}</p>
              </:item>

              <:item title="Deskripsi">
                <p class="text-gray-400 mt-3 md:pr-32">{@category.description}</p>
              </:item>
            </.list>
          </div>
        </div>

        <%!-------------------------%>
        <%!-- LIST ARTICLE--%>
        <%!-------------------------%>

        <section>
          <h1 class="my-10 text-2xl border-gray-500 border-b pb-5">List Artikel</h1>
          <%= if @category.articles == [] do %>
            <div class="h-[15rem] mx-auto rounded-lg text-center shadow-xl flex gap-5 flex-col items-center justify-center">
              <%!-------------------------%>
              <%!-- CATEGORY NOT FOUND --%>
              <%!-------------------------%>

              <p>
                Sorry, Artikel tidak ditemukan atau tidak tersedia
                <.link patch={~p"/admin/categories"} class="text-[#fedf16e0] font-bold">
                  <.icon name="hero-arrows-right-left" class="w-4 h-4" />
                  <span class="border-b pb-2 text-white hover:text-[#fedf16e0]">
                    Kembali ke pencarian
                  </span>
                </.link>
              </p>
              <.icon name="hero-no-symbol" class="w-10 h-10" />
            </div>
          <% else %>
            <%!-------------------------%>
            <%!-- CATEGORY FOUND --%>
            <%!-------------------------%>

            <div class="grid grid-cols-2 md:grid-cols-3 gap-6">
              <%= for article <- @category.articles do %>
                <.link
                  href={~p"/articles/#{article.id}"}
                  class="group card bg-base-200 hover:bg-base-300 transition-all duration-300 hover:shadow-xl"
                >
                  <figure class="relative overflow-hidden h-48">
                    <img
                      src={article.image}
                      alt={article.article_name}
                      class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                    />
                  </figure>
                  <div class="card-body">
                    <h3 class="card-title text-lg group-hover:text-primary transition-colors">
                      {article.article_name}
                    </h3>
                    <p class="text-sm text-base-content/70 line-clamp-2">
                      {article.content |> quill_plain_text() |> String.slice(0, 120)}...
                    </p>
                  </div>
                </.link>
              <% end %>
            </div>
          <% end %>
        </section>
      </div>
    </Layouts.app>
    """
  end

  # ============================================================================
  # QUILL TEXT EDITOR
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
end

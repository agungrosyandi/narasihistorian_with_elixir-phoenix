defmodule NarasihistorianWeb.Admin.CategoryLive.Show do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Categories

  import NarasihistorianWeb.CustomComponents, only: [quill_plain_text: 1, truncate: 2]

  # ============================================================================
  # MOUNT
  # ============================================================================

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    category_by_id = Categories.get_category!(id)
    count_articles_by_category = Categories.count_articles_by_category(id)

    {:ok,
     socket
     |> assign(:page_title, "Show Category")
     |> assign(:category, category_by_id)
     |> assign(:next_cursor, nil)
     |> assign(:end_of_list?, false)
     |> assign(:total_articles, count_articles_by_category)
     |> assign(:loaded_count, 0)
     |> stream(:articles, [])
     |> load_more_articles(id)}
  end

  # ============================================================================
  # RENDER
  # ============================================================================

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="mb-14">
        <%!------------------------------%>
        <%!-- HEADER --%>
        <%!------------------------------%>

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

        <%!------------------------------%>
        <%!-- CATEGORY INFO --%>
        <%!------------------------------%>

        <div class="flex flex-col gap-5 lg:flex-row">
          <div class="w-[100%] flex-1">
            <img
              class="relative h-full w-full object-cover rounded-xl"
              src={@category.image_category}
              alt={@category.category_name}
            />
          </div>

          <div class="flex-[2_1_0%] shadow-2xl rounded-xl">
            <.list>
              <:item title="Kategori">
                <p class="text-gray-400 mt-3">{@category.category_name}</p>
              </:item>
              <:item title="Deskripsi">
                <p class="text-gray-400 mt-3 md:pr-32">{@category.description}</p>
              </:item>
            </.list>
          </div>
        </div>

        <%!------------------------------%>
        <%!-- ARTICLES LIST --%>
        <%!------------------------------%>

        <section>
          <h1 class="my-10 text-2xl border-gray-500 border-b pb-5">List Artikel</h1>

          <div id="articles" phx-update="stream" class="grid grid-cols-2 md:grid-cols-3 gap-6">
            <div
              :for={{dom_id, article} <- @streams.articles}
              id={dom_id}
            >
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
                    {truncate(article.article_name, 50)}
                  </h3>
                  <p class="text-sm text-base-content/70 line-clamp-2">
                    {article.content |> quill_plain_text() |> String.slice(0, 100)}...
                  </p>
                </div>
              </.link>
            </div>
          </div>

          <%!------------------------------%>
          <%!-- EMPTY STATE --%>
          <%!------------------------------%>

          <div
            :if={@streams.articles == %Phoenix.LiveView.LiveStream{} && @end_of_list?}
            class="h-[15rem] mx-auto rounded-lg text-center shadow-xl flex gap-5 flex-col items-center justify-center"
          >
            <span>
              Sorry, Artikel tidak ditemukan atau tidak tersedia
              <.link patch={~p"/admin/categories"} class="text-[#fedf16e0] font-bold">
                <.icon name="hero-arrows-right-left" class="w-4 h-4" />
                <span class="border-b pb-2 text-white hover:text-[#fedf16e0]">
                  Kembali ke pencarian
                </span>
              </.link>
            </span>
            <.icon name="hero-no-symbol" class="w-10 h-10" />
          </div>

          <%!------------------------------%>
          <%!-- LOAD MORE / END --%>
          <%!------------------------------%>

          <div class="flex flex-col gap-5 justify-center items-center mt-8">
            <div>
              <.button_custom
                :if={!@end_of_list?}
                variant="transparant"
                phx-click="load-more"
                phx-disable-with="Loading..."
              >
                Muat Lebih Banyak
              </.button_custom>
            </div>

            <span class="text-sm font-normal text-gray-300 flex items-center gap-2">
              {@loaded_count} dari {@total_articles} Total Artikel
            </span>

            <span :if={@end_of_list?} class="text-gray-500 text-sm">
              Semua artikel telah ditampilkan
            </span>
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end

  # ============================================================================
  # HANDLE EVENT
  # ============================================================================

  @impl true
  def handle_event("load-more", _params, socket) do
    category_id = socket.assigns.category.id

    {:noreply, load_more_articles(socket, category_id)}
  end

  # ============================================================================
  # PRIVATE — load articles with cursor
  # ============================================================================

  defp load_more_articles(socket, category_id) do
    cursor = socket.assigns.next_cursor

    %{articles: articles, next_cursor: next_cursor} =
      Categories.list_articles_by_category(category_id, cursor)

    loaded = socket.assigns[:loaded_count] || 0

    socket
    |> stream(:articles, articles)
    |> assign(:next_cursor, next_cursor)
    |> assign(:loaded_count, loaded + length(articles))
    |> assign(:end_of_list?, is_nil(next_cursor) && length(articles) < 9)
  end
end

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
      <.header>
        <:actions>
          <div class="my-5 flex flex-row gap-3">
            <.button_custom variant="transparant" navigate={~p"/admin/categories"}>
              <.icon name="hero-arrow-left" />
            </.button_custom>
            <.button_custom
              variant="primary"
              navigate={~p"/admin/categories/#{@category}/edit?return_to=show"}
            >
              <.icon name="hero-pencil-square" /> Edit category
            </.button_custom>
          </div>
        </:actions>
      </.header>

      <.list>
        <:item title="Kategori">
          <p class="text-gray-400 mt-3">{@category.category_name}</p>
        </:item>
        <:item title="Slug">
          <p class="text-gray-400 mt-3">{@category.slug}</p>
        </:item>
      </.list>
      
    <!-- associate with articles -->

      <section>
        <h1 class="my-5">Articles related</h1>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
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
      </section>
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

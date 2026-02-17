defmodule NarasihistorianWeb.Admin.CategoryLive.Index do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Categories

  import NarasihistorianWeb.CustomComponents, only: [admin_user_nav: 1]

  @take_page 1
  @take_per_page 5

  # ============================================================================
  # MOUNT
  # ============================================================================

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_user.role == :admin do
      socket =
        socket
        |> assign(:page_title, "Kategori")
        |> assign(:current_page, :categories)
        |> assign(page: @take_page, per_page: @take_per_page)
        |> assign(:end_of_list?, false)
        |> stream(:categories, [])
        |> load_categories()

      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "Akses ke Kategori terbatas hanya untuk admin")
       |> redirect(to: ~p"/")}
    end
  end

  # ============================================================================
  # RENDER
  # ============================================================================

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto mb-14">
        <%!-------------------------%>
        <%!-- ADMIN NAVIGATION --%>
        <%!-------------------------%>

        <.admin_user_nav current_page={@current_page} current_user={@current_user} />

        <%!-------------------------%>
        <%!-- HEADER --%>
        <%!-------------------------%>

        <.header>
          <:actions>
            <div class="flex justify-end mb-8">
              <.link navigate={~p"/admin/categories/new"}>
                <.span_custom variant="transparant">
                  <.icon name="hero-plus" class="w-4 h-4 mb-1 mr-2" /> Buat Kategori
                </.span_custom>
              </.link>
            </div>
          </:actions>
        </.header>

        <%!-------------------------%>
        <%!-- CATEGORIES TABLE --%>
        <%!-------------------------%>

        <div class="border border-gray-600 p-3 rounded-lg overflow-x-auto">
          <.table
            id="categories"
            rows={@streams.categories}
            row_click={fn {_id, category} -> JS.navigate(~p"/admin/categories/#{category}") end}
          >
            <:col :let={{_id, category}} label="Kategori">
              {category.category_name}
            </:col>
            <:col :let={{_id, category}} label="Slug">
              {category.slug}
            </:col>
            <:action :let={{_id, category}}>
              <div class="sr-only">
                <.link navigate={~p"/admin/categories/#{category}"}>Show</.link>
              </div>
              <.link navigate={~p"/admin/categories/#{category}/edit"}>Edit</.link>
            </:action>
            <:action :let={{_id, category}}>
              <.link
                phx-click={JS.push("delete", value: %{id: category.id})}
                data-confirm="Are you sure?"
              >
                Delete
              </.link>
            </:action>
          </.table>
        </div>

        <%!-------------------------%>
        <%!-- LOAD MORE BUTTON --%>
        <%!-------------------------%>

        <div class="flex justify-center mt-6">
          <.button_custom
            :if={!@end_of_list?}
            variant="transparant"
            phx-click="load-more"
            phx-disable-with="Loading..."
          >
            Muat Lebih Banyak
          </.button_custom>

          <p :if={@end_of_list?} class="text-gray-500 text-sm">
            Semua kategori telah ditampilkan
          </p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # ============================================================================
  # HANDLE EVENT
  # ============================================================================

  @impl true
  def handle_event("load-more", _params, socket) do
    socket =
      socket
      |> update(:page, &(&1 + 1))
      |> load_categories()

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    category = Categories.get_category!(id)

    case Categories.delete_category(category) do
      {:ok, _} ->
        {:noreply,
         socket
         |> stream_delete(:categories, category)
         |> put_flash(:info, "Kategori berhasil dihapus")}

      {:error, :has_articles} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Untuk menghapus kategori, hapus terlebh dahulu artikel yang berkaitan dengan kategori yang ingin dihapus "
         )}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Gagal menghapus kategori")}
    end
  end

  # ============================================================================
  # PRIVATE HELPER LOAD CATEGORIES
  # ============================================================================

  defp load_categories(socket) do
    %{page: page, per_page: per_page} = socket.assigns

    categories = Categories.list_categories(page: page, per_page: per_page)

    socket
    |> stream(:categories, categories)
    |> assign(:end_of_list?, length(categories) < per_page)
  end
end

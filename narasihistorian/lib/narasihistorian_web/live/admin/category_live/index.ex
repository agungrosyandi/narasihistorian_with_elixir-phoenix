defmodule NarasihistorianWeb.Admin.CategoryLive.Index do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Categories

  import NarasihistorianWeb.Admin.Components, only: [admin_nav: 1]

  # ============================================================================
  # MOUNT
  # ============================================================================

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_user.role == :admin do
      {:ok,
       socket
       |> assign(:page_title, "Kategori")
       |> stream(:categories, list_categories())
       |> assign(:current_page, :categories)}
    else
      {:ok,
       socket
       |> put_flash(:error, "You must be an admin to access categories")
       |> redirect(to: ~p"/admin/articles")}
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
        <%!-- Admin Navigation --%>

        <.admin_nav current_page={@current_page} current_user={@current_user} />

        <%!-- Header --%>

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

        <%!-- Categories Table --%>

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
            <:action :let={{id, category}}>
              <.link
                phx-click={JS.push("delete", value: %{id: category.id}) |> hide("##{id}")}
                data-confirm="Are you sure?"
              >
                Delete
              </.link>
            </:action>
          </.table>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # ============================================================================
  # HANDLE EVENT
  # ============================================================================

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    category = Categories.get_category!(id)
    {:ok, _} = Categories.delete_category(category)

    {:noreply, stream_delete(socket, :categories, category)}
  end

  # ============================================================================
  # PRIVATE HELPER
  # ============================================================================

  defp list_categories do
    Categories.list_categories()
  end
end

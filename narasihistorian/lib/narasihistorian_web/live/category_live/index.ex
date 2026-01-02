defmodule NarasihistorianWeb.Admin.CategoryLive.Index do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Categories

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Categories
        <:actions>
          <.button variant="primary" navigate={~p"/admin/categories/new"}>
            <.icon name="hero-plus" /> New Category
          </.button>
        </:actions>
      </.header>

      <.table
        id="categories"
        rows={@streams.categories}
        row_click={fn {_id, category} -> JS.navigate(~p"/admin/categories/#{category}") end}
      >
        <:col :let={{_id, category}} label="Category name">{category.category_name}</:col>
        <:col :let={{_id, category}} label="Slug">{category.slug}</:col>
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
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Categories")
     |> stream(:categories, list_categories())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    category = Categories.get_category!(id)
    {:ok, _} = Categories.delete_category(category)

    {:noreply, stream_delete(socket, :categories, category)}
  end

  defp list_categories() do
    Categories.list_categories()
  end
end

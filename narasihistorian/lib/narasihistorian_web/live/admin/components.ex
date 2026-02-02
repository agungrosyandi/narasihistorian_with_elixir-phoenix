defmodule NarasihistorianWeb.Admin.Components do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: NarasihistorianWeb.Endpoint,
    router: NarasihistorianWeb.Router

  # ============================================================================
  # admin nav
  # ============================================================================

  attr :current_page, :atom, required: true
  attr :current_user, :map, required: true

  def admin_nav(assigns) do
    ~H"""
    <div class="flex flex-row gap-5 mb-10">
      <.nav_item path={~p"/admin/dashboard"} current={@current_page} page={:dashboard}>
        Dashboard
      </.nav_item>

      <.nav_item path={~p"/admin/articles"} current={@current_page} page={:articles}>
        Artikel
      </.nav_item>

      <%= if @current_user.role == :admin do %>
        <.nav_item path={~p"/admin/categories"} current={@current_page} page={:categories}>
          Kategori
        </.nav_item>
      <% end %>
    </div>
    """
  end

  # ============================================================================
  # NAV ITEM
  # ============================================================================

  attr :path, :string, required: true
  attr :current, :atom, required: true
  attr :page, :atom, required: true
  slot :inner_block, required: true

  defp nav_item(assigns) do
    ~H"""
    <.link
      navigate={@path}
      class={[
        "px-4 py-2 rounded-lg font-medium transition-all duration-200",
        if(@current == @page,
          do: "bg-primary text-black shadow-md",
          else: "text-gray-300 hover:bg-gray-100 hover:text-gray-900"
        )
      ]}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end
end

defmodule NarasihistorianWeb.CustomComponents do
  use NarasihistorianWeb, :html

  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: NarasihistorianWeb.Endpoint,
    router: NarasihistorianWeb.Router

  # ============================================================================
  # ADMIN & USER ROLE SELECTED NAVBAR
  # ============================================================================

  attr :current_page, :atom, required: true
  attr :current_user, :map, required: true

  def admin_user_nav(assigns) do
    ~H"""
    <div class="flex flex-row gap-5 pb-5 mb-10 border-b border-gray-500">
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

  attr :path, :string, required: true
  attr :current, :atom, required: true
  attr :page, :atom, required: true
  slot :inner_block, required: true

  defp nav_item(assigns) do
    ~H"""
    <.link
      navigate={@path}
      class={[
        "py-2 px-3 font-medium transition-all duration-200",
        if(@current == @page,
          do: "border-b border-[#fedf16e0] text-gray-100",
          else: "text-gray-300 hover:text-[#fedf16e0]"
        )
      ]}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  # ============================================================================
  # SETTINGS NAV SELECTED NAVBAR
  # ============================================================================

  attr :current_page, :atom, required: true
  attr :current_user, :map, required: true

  def settings_nav(assigns) do
    ~H"""
    <div>
      <div class="flex flex-col gap-2 justify-center w-full text-center items-center mb-5">
        <h1 class="text-xl sm:text-2xl font-bold">
          Account Settings
        </h1>
        <p class="text-sm sm:text-base text-gray-400 px-4">
          Manage your account email address and password settings
        </p>
      </div>
      
    <!-- Desktop Navigation - Horizontal tabs -->

      <div class="hidden sm:flex flex-row gap-5 pb-5 mb-10 border-b border-gray-500">
        <.desktop_nav_item path={~p"/users/settings"} current={@current_page} page={:settings}>
          <.icon name="hero-envelope" class="w-4 h-4 mr-2" /> Email
        </.desktop_nav_item>

        <.desktop_nav_item
          path={~p"/users/settings/change-username"}
          current={@current_page}
          page={:change_username}
        >
          <.icon name="hero-user" class="w-4 h-4 mr-2" /> Username
        </.desktop_nav_item>

        <.desktop_nav_item
          path={~p"/users/settings/change-password"}
          current={@current_page}
          page={:change_password}
        >
          <.icon name="hero-lock-closed" class="w-4 h-4 mr-2" /> Password
        </.desktop_nav_item>
      </div>
      
    <!-- Mobile Navigation - Toggle/Segmented Control Style -->

      <div class="sm:hidden mb-8">
        <div class="bg-gray-800 rounded-lg p-1 flex gap-1">
          <.mobile_nav_item path={~p"/users/settings"} current={@current_page} page={:settings}>
            <.icon name="hero-envelope" class="w-4 h-4 sm:mr-2" />
            <span class="hidden xs:inline">Email</span>
          </.mobile_nav_item>

          <.mobile_nav_item
            path={~p"/users/settings/change-username"}
            current={@current_page}
            page={:change_username}
          >
            <.icon name="hero-user" class="w-4 h-4 sm:mr-2" />
            <span class="hidden xs:inline">Username</span>
          </.mobile_nav_item>

          <.mobile_nav_item
            path={~p"/users/settings/change-password"}
            current={@current_page}
            page={:change_password}
          >
            <.icon name="hero-lock-closed" class="w-4 h-4 sm:mr-2" />
            <span class="hidden xs:inline">Password</span>
          </.mobile_nav_item>
        </div>
      </div>
    </div>
    """
  end

  attr :path, :string, required: true
  attr :current, :atom, required: true
  attr :page, :atom, required: true
  slot :inner_block, required: true

  defp desktop_nav_item(assigns) do
    ~H"""
    <.link
      navigate={@path}
      class={[
        "flex items-center py-2 px-3 font-medium transition-all duration-200 whitespace-nowrap",
        if(@current == @page,
          do: "border-b-2 border-[#fedf16e0] text-gray-100",
          else: "text-gray-300 hover:text-[#fedf16e0]"
        )
      ]}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  attr :path, :string, required: true
  attr :current, :atom, required: true
  attr :page, :atom, required: true
  slot :inner_block, required: true

  defp mobile_nav_item(assigns) do
    ~H"""
    <.link
      navigate={@path}
      class={[
        "flex-1 flex items-center justify-center gap-1.5 py-2.5 px-2 rounded-md font-medium transition-all duration-200 text-sm",
        if(@current == @page,
          do: "bg-[#fedf16e0] text-gray-900 shadow-sm",
          else: "text-gray-400 hover:text-gray-200"
        )
      ]}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end
end

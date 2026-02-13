defmodule NarasihistorianWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use NarasihistorianWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :current_user, :map, default: nil, doc: "the current authenticated user"
  attr :current_scope, :map, default: nil, doc: "the current scope"

  slot :inner_block, required: true

  # Helper to return the correct dashboard path based on user role

  defp dashboard_path(user) do
    if user.role == :admin, do: "/admin/dashboard", else: "/user/dashboard"
  end

  def app(assigns) do
    ~H"""
    <%!-- NAVBAR --%>

    <main class="relative w-[90%] mx-auto lg:w-[85%] xl:w-[70%]">
      <.header>
        <nav class="py-5">
          <div class="flex items-center justify-between">
            <%!-- Logo --%>

            <.link href={~p"/"}>
              <img
                class="h-[2rem] w-[12rem] md:h-[2rem] md:w-[15rem] lg:h-[5rem] lg:w-[13rem] object-cover"
                src="/images/logo-narasihistorian-1-02-1.png"
                alt="Narasi Historian"
              />
            </.link>

            <%!-- Desktop Navigation & User Menu --%>

            <div class="hidden md:flex items-center gap-8">
              <.link
                href={~p"/articles"}
                class="text-white hover:text-[#fedf16e0] font-normal text-base transition-colors duration-200"
              >
                Artikel
              </.link>

              <.link
                href={~p"/categories"}
                class="text-white hover:text-[#fedf16e0] font-normal text-base transition-colors duration-200"
              >
                Kategori
              </.link>

              <%= if Map.get(assigns, :current_user) do %>
                <%!-- Desktop Avatar Dropdown --%>

                <div class="relative" id="desktop-user-menu">
                  <button
                    phx-click={
                      JS.toggle(to: "#desktop-dropdown")
                      |> JS.toggle_class("hidden", to: "#desktop-dropdown")
                    }
                    class="flex items-center gap-2 p-1 rounded-full hover:bg-white/10 transition-colors duration-200"
                  >
                    <div class="w-10 h-10 rounded-full bg-gradient-to-br from-[#fedf16e0] to-yellow-600 flex items-center justify-center text-white font-bold text-sm shadow-lg">
                      {String.first(@current_user.username) |> String.upcase()}
                    </div>
                  </button>

                  <%!-- Dropdown Menu --%>

                  <div
                    id="desktop-dropdown"
                    class="hidden absolute right-0 mt-2 w-56 bg-base-100 rounded-lg shadow-xl border border-gray-700 overflow-hidden z-50"
                    phx-click-away={JS.add_class("hidden", to: "#desktop-dropdown")}
                  >
                    <%!-- User Info --%>

                    <div class="px-4 py-3 border-b border-gray-700">
                      <p class="text-sm font-medium text-white">{@current_user.username}</p>
                      <p class="text-xs text-gray-400 truncate">{@current_user.email}</p>
                    </div>

                    <%!-- Menu Items --%>

                    <div class="py-2">
                      <.link
                        href={dashboard_path(@current_user)}
                        class="flex items-center gap-3 px-4 py-2 text-sm text-white hover:bg-white/10 transition-colors duration-200"
                      >
                        <.icon name="hero-squares-plus" class="w-5 h-5" /> Dashboard
                      </.link>

                      <.link
                        href={~p"/users/settings"}
                        class="flex items-center gap-3 px-4 py-2 text-sm text-white hover:bg-white/10 transition-colors duration-200"
                      >
                        <.icon name="hero-cog-8-tooth" class="w-5 h-5" /> Settings
                      </.link>

                      <.link
                        href={~p"/users/log-out"}
                        method="delete"
                        class="flex items-center gap-3 px-4 py-2 text-sm text-red-400 hover:bg-red-500/10 transition-colors duration-200"
                      >
                        <.icon name="hero-arrow-right-start-on-rectangle" class="w-5 h-5" /> Log out
                      </.link>
                    </div>
                  </div>
                </div>
              <% else %>
                <.link
                  href={~p"/users/log-in"}
                  class="text-white text-sm border border-white/30 py-2 px-6 rounded-full hover:bg-white/10 hover:border-[#fedf16e0] font-normal transition-all duration-200"
                >
                  Login
                </.link>
              <% end %>
            </div>

            <%!-- Mobile Menu Button --%>

            <button
              id="mobile-menu-button"
              class="md:hidden p-2 rounded-lg hover:bg-gray-100/10 transition-colors duration-200 z-50"
              phx-click={
                JS.toggle(to: "#mobile-menu") |> JS.toggle_class("hidden", to: "#mobile-menu")
              }
            >
              <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4 6h16M4 12h16M4 18h16"
                />
              </svg>
            </button>
          </div>

          <%!-- Mobile Menu --%>

          <div
            id="mobile-menu"
            class="hidden md:hidden mt-5 pb-4 border-t border-b border-gray-500"
          >
            <div class="flex flex-col gap-4 pt-4">
              <%!-- Mobile User Info --%>

              <%= if Map.get(assigns, :current_user) do %>
                <div class="flex items-center gap-3 px-4 py-3 bg-white/5 rounded-lg mb-2">
                  <div class="w-12 h-12 rounded-full bg-gradient-to-br from-[#fedf16e0] to-yellow-600 flex items-center justify-center text-white font-bold shadow-lg">
                    {String.first(@current_user.username) |> String.upcase()}
                  </div>
                  <div>
                    <p class="text-white font-medium">{@current_user.username}</p>
                    <p class="text-xs text-gray-400">{@current_user.email}</p>
                  </div>
                </div>
              <% end %>

              <%= if Map.get(assigns, :current_user) do %>
                <.link
                  href={dashboard_path(@current_user)}
                  class="flex items-center gap-3 text-base text-white hover:text-[#fedf16e0] font-medium transition-colors duration-200 py-2 px-4"
                >
                  <.icon name="hero-squares-plus" class="w-5 h-5" /> Dashboard
                </.link>

                <.link
                  href={~p"/users/settings"}
                  class="flex items-center gap-3 text-base text-white hover:text-[#fedf16e0] font-medium transition-colors duration-200 py-2 px-4"
                >
                  <.icon name="hero-cog-8-tooth" class="w-5 h-5" /> Settings
                </.link>

                <.link
                  href={~p"/users/log-out"}
                  method="delete"
                  class="flex items-center gap-3 text-base text-red-400 hover:text-red-300 font-medium transition-colors duration-200 py-2 px-4"
                >
                  <.icon name="hero-arrow-right-start-on-rectangle" class="w-5 h-5" /> Log out
                </.link>

                <div class="border-t border-gray-500 my-2"></div>
              <% else %>
                <.link
                  href={~p"/users/log-in"}
                  class="text-white hover:text-[#fedf16e0] text-base font-medium transition-colors duration-200 py-2 px-4"
                >
                  <.icon name="hero-user-circle" class="w-5 h-5 mr-2 mb-1" /> Login
                </.link>
              <% end %>

              <%!-- NAVBAR MENU --%>

              <.link
                href={~p"/articles"}
                class="text-white hover:text-[#fedf16e0] text-base font-medium transition-colors duration-200 py-2 px-4"
              >
                <.icon name="hero-chevron-right" class="w-5 h-5 mr-2 mb-1" /> Artikel
              </.link>

              <.link
                href={~p"/"}
                class="text-white hover:text-[#fedf16e0] text-base font-medium transition-colors duration-200 py-2 px-4"
              >
                <.icon name="hero-chevron-right" class="w-5 h-5 mr-2 mb-1" /> Kategori
              </.link>
            </div>
          </div>
        </nav>
      </.header>

      <%!-- MAIN RENDER --%>

      <div class="">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end

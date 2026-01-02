defmodule NarasihistorianWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use NarasihistorianWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <%!-- NAVBAR --%>

    <main class="relative w-[90%] mx-auto lg:w-[85%] xl:w-[80%]">
      <.header>
        <nav class="py-5">
          <div class="flex items-center justify-between">
            <%!-- Logo --%>
            <div class="relative">
              <.link href={~p"/"}>
                <img
                  class="h-[2rem] w-[8rem] md:h-[3rem] md:w-[11rem] lg:h-[5rem] lg:w-[13rem] object-cover"
                  src="/images/logo-narasihistorian-1-02-1.png"
                  alt="Narasi Historian"
                />
              </.link>
            </div>

            <%!-- Desktop Navigation --%>

            <div class="hidden md:flex items-center gap-8">
              <.link
                href={~p"/articles"}
                class="text-white hover:text-[#fedf16e0] font-medium transition-colors duration-200"
              >
                Article
              </.link>

              <.link
                href={~p"/admin/articles"}
                class="text-white hover:text-[#fedf16e0] font-medium transition-colors duration-200"
              >
                Admin
              </.link>

              <.link
                href={~p"/admin/categories"}
                class="text-white hover:text-[#fedf16e0] font-medium transition-colors duration-200"
              >
                Category
              </.link>
            </div>

            <%!-- Mobile Menu Button --%>

            <button
              id="mobile-menu-button"
              class="md:hidden p-2 rounded-lg hover:bg-gray-100 transition-colors duration-200 z-50"
              phx-click={
                JS.toggle(to: "#mobile-menu") |> JS.toggle_class("hidden", to: "#mobile-menu")
              }
            >
              <svg class="w-6 h-6 text-gray-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
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
            class="hidden md:hidden mt-4 pb-4 border-t border-gray-500"
          >
            <div class="flex flex-col gap-4 pt-4">
              <.link
                href={~p"/articles"}
                class="text-white hover:text-[#fedf16e0] font-medium transition-colors duration-200 py-2"
              >
                Article
              </.link>

              <.link
                href={~p"/admin/articles"}
                class="text-white hover:text-[#fedf16e0] font-medium transition-colors duration-200 py-2"
              >
                Admin
              </.link>

              <.link
                href={~p"/admin/categories"}
                class="text-white hover:text-[#fedf16e0] font-medium transition-colors duration-200 py-2"
              >
                Category
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

  ## Examples

      <.flash_group flash={@flash} />
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

  See <head> in root.html.heex which applies the theme before page load.
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

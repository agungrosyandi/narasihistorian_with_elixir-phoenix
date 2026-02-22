defmodule NarasihistorianWeb.CustomComponents do
  use NarasihistorianWeb, :html

  use Phoenix.Component
  # import Phoenix.LiveView.JS

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

  # ===========================================================================
  # MODAL
  # ============================================================================

  @moduledoc """
  A reusable, minimalist modern modal component for Phoenix LiveView.

  ## Usage

      <.modal id="confirm-modal" on_confirm={JS.push("delete")}>
        <:title>Delete Item</:title>
        <:body>
          Are you sure you want to delete this item? This action cannot be undone.
        </:body>
        <:confirm>Delete</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>

  To show the modal:
      JS.show(to: "#confirm-modal")

  To hide the modal:
      JS.hide(to: "#confirm-modal")
  """

  @doc """
  Renders a modal dialog with customizable content and actions.

  ## Attributes
  - `id` - Required. The DOM id for the modal
  - `show` - Optional. Boolean to show/hide modal on mount (default: false)
  - `on_cancel` - Optional. JS commands to execute on cancel
  - `on_confirm` - Optional. JS commands to execute on confirm

  ## Slots
  - `title` - The modal header/title
  - `body` - The main modal content
  - `confirm` - The confirm button text (shows confirm button if present)
  - `cancel` - The cancel button text (default: "Cancel")
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  attr :on_confirm, JS, default: %JS{}

  slot :title
  slot :body
  slot :confirm
  slot :cancel

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <!-- Backdrop -->

      <div
        id={"#{@id}-backdrop"}
        class="fixed inset-0 bg-black/50 backdrop-blur-sm transition-opacity"
        aria-hidden="true"
      />
      
    <!-- Modal container -->

      <div class="fixed inset-0 overflow-y-auto">
        <div class="flex min-h-full items-center justify-center p-4">
          <div
            id={"#{@id}-panel"}
            class="relative w-full max-w-2xl transform overflow-hidden rounded-2xl border border-gray-500 shadow-2xl transition-all"
            aria-labelledby={"#{@id}-title"}
            aria-describedby={"#{@id}-description"}
            role="dialog"
            aria-modal="true"
            tabindex="0"
            phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
            phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
            phx-key="escape"
          >
            <!-- Close button -->

            <button
              type="button"
              class="absolute right-4 top-4 text-gray-400 hover:text-gray-600 transition-colors cursor-pointer"
              aria-label="Close"
              phx-click={JS.exec("data-cancel", to: "##{@id}")}
            >
              <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
            
    <!-- Content -->

            <div class="p-6">
              <!-- Title -->
              <div :if={@title != []} class="mb-4">
                <h3 id={"#{@id}-title"} class="text-xl font-semibold text-gray-900">
                  {render_slot(@title)}
                </h3>
              </div>
              
    <!-- Body -->

              <div
                :if={@body != []}
                id={"#{@id}-description"}
                class="text-gray-600 text-sm leading-relaxed"
              >
                {render_slot(@body)}
              </div>
            </div>
            
    <!-- Actions -->

            <div
              :if={@confirm != [] or @cancel != []}
              class="px-6 pb-10 flex gap-3 justify-start rounded-b-2xl"
            >
              <button
                :if={@cancel != []}
                type="button"
                phx-click={JS.exec("data-cancel", to: "##{@id}")}
              >
                {render_slot(@cancel)}
              </button>

              <div :if={@confirm != []}>
                {render_slot(@confirm)}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Shows a modal by its ID.

  ## Examples
      JS.show(to: "#my-modal")
      # or
      show_modal("my-modal")
  """
  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(
      to: "##{id}",
      transition: {"ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-backdrop",
      transition: {"ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-panel",
      transition:
        {"ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-panel")
  end

  @doc """
  Hides a modal by its ID.

  ## Examples
      JS.hide(to: "#my-modal")
      # or
      hide_modal("my-modal")
  """
  def hide_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.hide(
      to: "##{id}",
      transition: {"ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-backdrop",
      transition: {"ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-panel",
      transition:
        {"ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  # =============================================
  # SIDEBAR DASHBOARD ADMIN / USER
  # =============================================

  # ============================================================================
  # admin_sidebar/1
  # Shared sidebar used across DashboardLive, DraftsLive, ProfileLive.
  #
  # Usage:
  #   <.admin_sidebar
  #     active={:dashboard}   # :dashboard | :drafts | :profile
  #     current_user={@current_user}
  #     sidebar_open={@sidebar_open}
  #     draft_count={@draft_count}
  #   />
  # ============================================================================

  attr :active, :atom, required: true
  attr :current_user, :map, required: true
  attr :sidebar_open, :boolean, default: false
  attr :draft_count, :integer, default: 0

  def admin_sidebar(assigns) do
    ~H"""
    <aside class={[
      "fixed top-0 left-0 z-30 h-full w-64 flex flex-col",
      "mr-5 rounded-xl shadow-xl border-r border-gray-800",
      "transition-transform duration-300 ease-in-out",
      "lg:translate-x-0 lg:static lg:z-auto",
      if(@sidebar_open, do: "translate-x-0", else: "-translate-x-full")
    ]}>
      <%!-- Header --%>

      <div class="flex items-center justify-between px-5 py-5 border-b border-gray-800">
        <div class="flex items-center gap-2.5">
          <div class="w-7 h-7 rounded-lg bg-[#fedf16] flex items-center justify-center">
            <span class="text-black text-xs font-black">N</span>
          </div>
          <span class="text-white font-semibold text-sm tracking-wide">Narasi Admin</span>
        </div>
        <button class="lg:hidden text-gray-500 hover:text-white" phx-click="toggle-sidebar">
          <.icon name="hero-x-mark" class="w-5 h-5" />
        </button>
      </div>

      <%!-- User info --%>

      <div class="px-5 py-4 border-b border-gray-800">
        <div class="flex items-center gap-3">
          <div class="w-9 h-9 rounded-full bg-gradient-to-br from-[#fedf16] to-amber-500 flex items-center justify-center shrink-0">
            <span class="text-black text-sm font-bold">
              {String.first(@current_user.username) |> String.upcase()}
            </span>
          </div>
          <div class="min-w-0">
            <p class="text-white text-sm font-medium truncate">{@current_user.username}</p>
            <p class="text-gray-500 text-xs truncate">{@current_user.email}</p>
          </div>
        </div>
      </div>

      <%!-- Nav --%>

      <nav class="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        <.sidebar_nav_link
          active={@active == :dashboard}
          navigate={~p"/admin/dashboard"}
          icon="hero-squares-2x2"
          label="Dashboard"
        />
        <.sidebar_nav_link
          active={@active == :drafts}
          navigate={~p"/admin/dashboard/drafts"}
          icon="hero-clock"
          label="Drafts"
          badge={@draft_count}
        />
        <.sidebar_nav_link
          active={@active == :profile}
          navigate={~p"/admin/dashboard/profile"}
          icon="hero-user-circle"
          label="Profile"
        />

        <div class="pt-3 mt-3 border-t border-gray-800">
          <p class="px-3 mb-2 text-xs font-semibold text-gray-600 uppercase tracking-wider">
            Manajemen
          </p>
          <.link
            navigate={~p"/admin/categories"}
            class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm text-gray-400 hover:text-white hover:bg-gray-800 transition-colors"
          >
            <.icon name="hero-tag" class="w-4 h-4 shrink-0" /> Kategori
          </.link>
          <.link
            navigate={~p"/admin/articles"}
            class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm text-gray-400 hover:text-white hover:bg-gray-800 transition-colors"
          >
            <.icon name="hero-document-text" class="w-4 h-4 shrink-0" /> Artikel
          </.link>
        </div>
      </nav>

      <%!-- Footer --%>

      <div class="px-3 py-4 border-t border-gray-800">
        <.link
          navigate={~p"/"}
          class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm text-gray-500 hover:text-white hover:bg-gray-800 transition-colors"
        >
          <.icon name="hero-arrow-left-on-rectangle" class="w-4 h-4 shrink-0" /> Keluar Admin
        </.link>
      </div>
    </aside>
    """
  end

  attr :active, :boolean, default: false
  attr :navigate, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :badge, :integer, default: nil

  defp sidebar_nav_link(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class={[
        "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm transition-colors",
        if(@active,
          do: "bg-[#fedf16]/10 text-[#fedf16]",
          else: "text-gray-400 hover:text-white hover:bg-gray-800"
        )
      ]}
    >
      <.icon name={@icon} class="w-4 h-4 shrink-0" />
      <span class="flex-1">{@label}</span>
      <span
        :if={@badge && @badge > 0}
        class="text-xs bg-amber-400/20 text-amber-400 rounded-full px-2 py-0.5 font-medium"
      >
        {@badge}
      </span>
    </.link>
    """
  end

  # =============================================
  # MOBILE SIDEBAR RESPNOSIVE
  # =============================================

  attr :active_tab, :string, required: true
  attr :on_toggle, :string, default: "toggle-sidebar"

  def mobile_topbar(assigns) do
    ~H"""
    <div class="lg:hidden flex items-center justify-between px-4 py-3 mb-5 border rounded-xl border-gray-600 shadow-xl ">
      <button
        phx-click={@on_toggle}
        class="text-gray-400 hover:text-white transition-colors"
      >
        <.icon name="hero-bars-3" class="w-6 h-6" />
      </button>

      <span class="text-white text-sm font-semibold">
        {tab_label(@active_tab)}
      </span>

      <div class="w-6" />
    </div>
    """
  end

  defp tab_label("dashboard"), do: "Dashboard"
  defp tab_label("drafts"), do: "drafts"
  defp tab_label("profile"), do: "profile"
  defp tab_label("settings"), do: "Settings"
  defp tab_label(tab), do: Phoenix.Naming.humanize(tab)

  # =============================================
  # REUSABLE PAGINATION
  # =============================================

  def pagination_controls(assigns) do
    assigns =
      assigns
      |> assign(:page_items, build_page_items(assigns.pagination))
      |> assign_new(:params, fn -> %{} end)

    ~H"""
    <div class="flex flex-col gap-5 items-center justify-between mt-6 lg:flex-row">
      <div class="text-sm text-gray-400">
        Showing {(@pagination.page - 1) * @pagination.per_page + 1} to {min(
          @pagination.page * @pagination.per_page,
          @pagination.total_count
        )} of {@pagination.total_count} results
      </div>

      <div class="join">
        
    <!-- Prev Arrow -->
        <%= if @pagination.page > 1 do %>
          <.link
            patch={build_pagination_path(@base_path, @params, @pagination.page - 1)}
            class="join-item btn btn-sm"
          >
            <.icon name="hero-chevron-double-left" class="w-4 h-4" />
          </.link>
        <% else %>
          <button class="join-item btn btn-sm btn-disabled">
            <.icon name="hero-chevron-double-left" class="w-4 h-4" />
          </button>
        <% end %>
        
    <!-- Page Numbers -->
        <%= for item <- @page_items do %>
          <%= if item == :ellipsis do %>
            <button class="join-item btn btn-sm btn-disabled">...</button>
          <% else %>
            <%= if item == @pagination.page do %>
              <button class="join-item btn btn-sm btn-active text-[#fedf16e0]">
                {item}
              </button>
            <% else %>
              <.link
                patch={build_pagination_path(@base_path, @params, item)}
                class="join-item btn btn-sm"
              >
                {item}
              </.link>
            <% end %>
          <% end %>
        <% end %>
        
    <!-- Next Arrow -->
        <%= if @pagination.page < @pagination.total_pages do %>
          <.link
            patch={build_pagination_path(@base_path, @params, @pagination.page + 1)}
            class="join-item btn btn-sm"
          >
            <.icon name="hero-chevron-double-right" class="w-4 h-4" />
          </.link>
        <% else %>
          <button class="join-item btn btn-sm btn-disabled">
            <.icon name="hero-chevron-double-right" class="w-4 h-4" />
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  defp build_page_items(%{page: _current, total_pages: total}) when total <= 5 do
    Enum.to_list(1..total)
  end

  defp build_page_items(%{page: current, total_pages: total}) do
    first_two = [1, 2]
    last_two = [total - 1, total]

    last_two_set = MapSet.new(last_two)
    first_two_set = MapSet.new(first_two)

    cond do
      current <= 2 or current >= total - 1 ->
        first_two ++ [:ellipsis] ++ last_two

      true ->
        middle =
          [current, current + 1]
          |> Enum.reject(&MapSet.member?(last_two_set, &1))
          |> Enum.reject(&MapSet.member?(first_two_set, &1))

        right =
          if Enum.empty?(middle),
            do: [],
            else: [:ellipsis] ++ last_two

        first_two ++ [:ellipsis] ++ middle ++ right
    end
  end

  defp build_pagination_path(base_path, params, page) do
    new_params =
      params
      |> Map.put("page", to_string(page))

    "#{base_path}?#{URI.encode_query(new_params)}"
  end

  # ============================================================================
  # TEXT UTILITIES
  # ============================================================================

  def truncate(text, length) when is_binary(text) do
    if String.length(text) > length do
      String.slice(text, 0, length) <> "..."
    else
      text
    end
  end

  def truncate(nil, _length), do: ""

  # ============================================================================
  # QUILL HTML → PLAIN TEXT
  # ============================================================================

  def quill_plain_text(nil), do: ""

  def quill_plain_text(html) when is_binary(html) do
    html
    |> String.replace(~r/<br\s*\/?>/i, " ")
    |> String.replace(~r/<\/p>/i, " ")
    |> String.replace(~r/<[^>]*>/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  def safe_quill_html(nil), do: ""

  def safe_quill_html(html), do: HtmlSanitizeEx.basic_html(html)

  # ============================================================================
  # TIME FORMAT INSTAGRAM STYLE
  # ============================================================================

  def time_ago_short(datetime) do
    now = DateTime.utc_now()

    datetime =
      case datetime do
        %NaiveDateTime{} ->
          DateTime.from_naive!(datetime, "Etc/UTC")

        %DateTime{} ->
          datetime
      end

    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 10 ->
        "Just now"

      diff < 60 ->
        "#{diff} detik yang lalu"

      diff < 3600 ->
        minutes = div(diff, 60)
        "#{minutes} menit yang lalu"

      diff < 86_400 ->
        hours = div(diff, 3600)
        "#{hours} jam yang lalu"

      diff < 604_800 ->
        days = div(diff, 86_400)
        "#{days} hari yang lalu"

      diff < 2_592_000 ->
        weeks = div(diff, 604_800)
        "#{weeks} minggu yang lalu"

      diff < 31_536_000 ->
        months = div(diff, 2_592_000)
        "#{months} bulan yang lalu"

      true ->
        years = div(diff, 31_536_000)
        "#{years} tahun yang lalu"
    end
  end

  # ============================================================================
  # TRUNCATE TEXT / DESCRIPTION
  # ============================================================================

  def reading_time(text) when is_binary(text) do
    word_count =
      text
      |> String.split()
      |> length()

    max(1, div(word_count, 200))
  end

  def reading_time(nil), do: 1

  # ============================================================================
  # ARTICLE CARD COMPONENT
  # ============================================================================

  attr :article, :map, required: true
  attr :base_path, :string, default: "/articles"

  def article_card(assigns) do
    ~H"""
    <.link
      navigate={"#{@base_path}/#{@article.id}"}
      class="group card shadow-2xl hover:bg-base-300 transition-all duration-300"
    >
      <!-- CATEGORY -->

      <div class="flex justify-start p-5 text-base font-bold">
        <.icon name="hero-list-bullet" class="w-5 h-5 mt-1 mr-2 text-[#fedf16e0]" />
        {@article.category.category_name}
      </div>

      <div class="flex flex-row md:flex-col">
        <!-- IMAGE -->

        <figure class="relative overflow-hidden rounded-xl h-64 flex-1 md:flex-auto">
          <img
            src={@article.image}
            alt={@article.article_name}
            class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
          />
        </figure>
        
    <!-- META -->

        <div class="card-body flex-1 md:flex-auto">
          <h2 class="card-title group-hover:text-primary transition-colors">
            {truncate(@article.article_name, 30)}
          </h2>

          <p class="text-base-content/70 line-clamp-3">
            {truncate(quill_plain_text(@article.content), 80)}
          </p>

          <p class="text-xs text-gray-300 mt-4">
            Penulis:
            <span class="text-white font-bold">
              {@article.user.username}
            </span>
          </p>

          <div class="flex flex-row flex-wrap justify-between items-center mt-2">
            <time class="text-xs pb-2">
              {time_ago_short(@article.inserted_at)}
            </time>

            <div class="text-xs text-gray-300 pb-2 flex items-center">
              <.icon name="hero-eye" class="w-4 h-4 mr-1" />
              {@article.view_count}
            </div>
          </div>
        </div>
      </div>
    </.link>
    """
  end

  # ============================================================================
  # LOAD MORE BUTTON (CURSOR PAGINATION)
  # ============================================================================

  attr :next_cursor, :string, default: nil
  attr :url, :string, required: true
  attr :target, :string, required: true
  attr :search_query, :string, default: nil
  attr :category, :string, default: nil
  attr :button_text, :string, default: "Muat Lebih Banyak"
  attr :finished_text, :string, default: "Semua artikel telah dimuat"

  def load_more(assigns) do
    ~H"""
    <%= if @next_cursor do %>
      <button
        id="load-more-btn"
        class="btn btn-outline border-[#fedf16e0] text-xs text-gray-100 hover:bg-[#fedf16e0] hover:text-black hover:border-[#fedf16e0] px-10"
        data-next-cursor={@next_cursor}
        data-search={@search_query}
        data-category={@category}
        data-url={@url}
        data-target={@target}
        onclick="loadMore(this)"
      >
        {@button_text}
      </button>
    <% else %>
      <p class="text-sm text-base-content/40 py-4">
        {@finished_text}
      </p>
    <% end %>
    """
  end

  # ============================================================================
  # ARTICLE CARD SWIPPER BIG CAROUSEL COMPONENT
  # ============================================================================

  attr :article, :map, required: true

  def article_card_swipper_big(assigns) do
    ~H"""
    <div
      class="swiper-slide popular-slide cursor-pointer group"
      data-href={~p"/articles/#{@article.id}"}
    >
      <div class="relative rounded-xl h-[420px] md:h-[520px] overflow-hidden">
        <%= if @article.image do %>
          <img
            src={@article.image}
            alt={@article.article_name}
            class="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
          />
        <% else %>
          <div class="w-full h-full bg-gray-800 flex items-center justify-center">
            <.icon name="hero-photo" class="w-16 h-16 text-gray-600" />
          </div>
        <% end %>
        
    <!-- Gradient -->

        <div class="absolute inset-0 bg-gradient-to-t from-black/90 via-black/40 to-transparent">
        </div>
        
    <!-- Content -->

        <div class="absolute bottom-0 left-0 right-0 p-6 md:p-10 max-w-3xl">
          <div class="flex items-center gap-3 mb-3">
            <span class="inline-block bg-[#fedf16e0] text-black text-xs font-bold uppercase tracking-wider px-3 py-1 rounded-sm">
              {@article.category.category_name}
            </span>

            <span class="flex items-center gap-1 text-gray-300 text-xs">
              <.icon name="hero-fire" class="w-3.5 h-3.5 text-orange-400" />
              {@article.view_count} views
            </span>
          </div>

          <h3 class="text-white font-bold text-xl md:text-3xl leading-tight mb-3 line-clamp-2">
            {@article.article_name}
          </h3>

          <div class="flex items-center gap-2 text-gray-400 text-xs">
            <span class="text-gray-300 font-medium">
              {@article.user.username}
            </span>
            <span>·</span>
            <time>{time_ago_short(@article.inserted_at)}</time>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :articles, :list, required: true
  attr :id, :string, required: true
  attr :class, :string, default: ""

  def card_swiper_carousel_big(assigns) do
    ~H"""
    <div class="relative mb-10">
      <div
        class={["swiper", @class]}
        id={@id}
      >
        <div class="swiper-wrapper">
          <%= for article <- @articles do %>
            <.article_card_swipper_big article={article} />
          <% end %>
        </div>
        
    <!-- Navigation -->

        <div
          id={"#{@id}Prev"}
          class="swiper-button-prev !text-[#fedf16e0] !w-5 !h-5 after:!text-base"
        >
        </div>

        <div
          id={"#{@id}Next"}
          class="swiper-button-next !text-[#fedf16e0] !w-5 !h-5 after:!text-base"
        >
        </div>
        
    <!-- Pagination -->

        <div
          id={"#{@id}Pagination"}
          class="swiper-pagination !bottom-3"
        >
        </div>
      </div>
    </div>
    """
  end

  # ============================================================================
  # ARTICLE CARD SWIPPER CAROUSEL COMPONENT
  # ============================================================================

  attr :article, :map, required: true

  def article_card_swipper(assigns) do
    ~H"""
    <.link
      href={~p"/articles/#{@article.id}"}
      class="group block shadow-2xl rounded-xl overflow-hidden hover:bg-base-300 transition-all duration-300 hover:-translate-y-1 hover:shadow-2xl h-full"
    >
      <!-- IMAGE -->

      <div class="relative h-44 overflow-hidden">
        <%= if @article.image do %>
          <img
            src={@article.image}
            alt={@article.article_name}
            class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
          />
        <% else %>
          <div class="w-full h-full bg-gray-700 flex items-center justify-center">
            <.icon name="hero-photo" class="w-10 h-10 text-gray-500" />
          </div>
        <% end %>
      </div>
      
    <!-- BODY -->

      <div class="p-5 flex flex-col gap-5">
        <h3 class="text-base font-bold text-white leading-snug line-clamp-2 group-hover:text-[#fedf16e0] transition-colors">
          {truncate(@article.article_name, 30)}
        </h3>

        <div class="flex items-center justify-between mt-auto text-xs text-gray-300 pt-2">
          <time>{time_ago_short(@article.inserted_at)}</time>
          <span class="flex items-center gap-1">
            <.icon name="hero-eye" class="w-3.5 h-3.5" />
            {@article.view_count}
          </span>
        </div>
      </div>
    </.link>
    """
  end

  attr :articles, :list, required: true
  attr :id, :string, required: true
  attr :class, :string, default: ""

  def card_swiper_carousel(assigns) do
    ~H"""
    <div class={["swiper", @class]} id={@id}>
      <div class="swiper-wrapper pb-10">
        <%= for article <- @articles do %>
          <div class="swiper-slide !h-auto">
            <.article_card_swipper article={article} />
          </div>
        <% end %>
      </div>
      
    <!-- NAVIGATION -->

      <div
        id={"#{@id}Prev"}
        class="swiper-button-prev !text-[#fedf16e0] !w-5 !h-5 hover:!text-white after:!text-base"
      >
      </div>

      <div
        id={"#{@id}Next"}
        class="swiper-button-next !text-[#fedf16e0] !w-5 !h-5 hover:!text-white after:!text-base"
      >
      </div>
      
    <!-- PAGINATION -->

      <div id={"#{@id}Pagination"} class="swiper-pagination"></div>
    </div>
    """
  end

  # ============================================================================
  # FOOTER PUBLIC PAGE
  # ============================================================================

  def footer_home_public_page(assigns) do
    ~H"""
    <div class="border-t border-gray-700 mt-10"></div>

    <footer class="relative gap-2 flex flex-col justify-between items-center py-10">
      <div class="relative flex flex-col justify-between items-center md:flex-row md:gap-10">
        <%!-- ------------- --%>
        <%!-- IMAGE --%>
        <%!-- ------------- --%>

        <div class="w-[100%] flex-1">
          <img
            class="relative h-[full] w-full object-cover rounded-xl"
            src="/images/closng-background-cover.jpg"
            alt="My Image"
          />
        </div>

        <%!-- ------------- --%>
        <%!-- DESCRIPTION --%>
        <%!-- ------------- --%>

        <div class="py-10 gap-5 flex-1 flex flex-col justify-center items-center md:px-5">
          <div>
            <span class="text-[#ffffffe0] font-bold text-xl">Tentang Narasi</span>
            <span class="text-[#fedf16e0] font-bold text-xl">Historian</span>
          </div>
          <p class="text-center text-base-content/60">
            Narasihistorian merupakan media konten yang berfokus pada sejarah
            peradaban global dengan visualisasi yang simple dan interaktif
            baik itu berupa konten artikel ataupun video infografik.
          </p>
        </div>
      </div>
      <div class="flex flex-row gap-5 justify-between w-full items-center">
        <small class="text-[#ffffffe0] font-bold text-xs">
          <.icon name="hero-minus-circle" class="w-4 h-4 mb-1 mr-1" /> 2024
        </small>
        <div class="flex items-center gap-5 text-xs">
          <.link
            href="mailto:agungrosyandi@gmail.com"
            class="text-white hover:text-[#fedf16e0] text-sm font-medium text-center transition-all duration-200"
          >
            <.icon name="hero-chevron-right" class="w-4 h-4 mb-1" /> Email
          </.link>
          <.link
            href="https://www.instagram.com/narasihistorian/"
            class="text-white hover:text-[#fedf16e0] text-sm font-medium text-center transition-all duration-200"
          >
            <.icon name="hero-chevron-right" class="w-4 h-4 mb-1" /> instagram
          </.link>
          <.link
            href="https://www.youtube.com/channel/UCNoUf4xYawhvK6dD94oDEDg"
            class="text-white hover:text-[#fedf16e0] text-sm font-medium text-center transition-all duration-200"
          >
            <.icon name="hero-chevron-right" class="w-4 h-4 mb-1" /> youtube
          </.link>
        </div>
      </div>
    </footer>
    """
  end

  # ============================================================================
  # SECTION HEADER
  # ============================================================================

  attr :title, :string, required: true
  attr :class, :string, default: ""
  attr :line_class, :string, default: "bg-white/30"
  attr :text_class, :string, default: "text-white/50"

  def section_header(assigns) do
    ~H"""
    <div class={["flex items-center gap-3 my-10", @class]}>
      <span class={["w-1 h-5 rounded-full block", @line_class]}></span>
      <h2 class={["text-sm font-bold uppercase tracking-widest", @text_class]}>
        {@title}
      </h2>
    </div>
    """
  end
end

defmodule NarasihistorianWeb.Admin.DashboardLive.Profile do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Drafts
  alias Narasihistorian.Dashboard

  import NarasihistorianWeb.CustomComponents,
    only: [admin_sidebar: 1, admin_user_nav: 1, mobile_topbar: 1]

  # =============================================
  # MOUNT
  # =============================================

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_user.role == :admin do
      user = socket.assigns.current_user

      draft_count = Drafts.count_drafts(user.id, "category")
      ratio = Dashboard.get_draft_vs_published_ratio_cached()

      {:ok,
       socket
       |> assign(:page_title, "Profile")
       |> assign(:current_page, :dashboard)
       |> assign(:sidebar_open, false)
       |> assign(:draft_count, draft_count)
       |> assign(:total_articles, ratio.total)
       |> assign(:active_tab, :profile)}
    else
      {:ok,
       socket
       |> put_flash(:error, "Akses ditolak")
       |> redirect(to: ~p"/")}
    end
  end

  # =============================================
  # HANDLE PARAMS
  # =============================================

  @impl true
  def handle_params(_params, _url, socket), do: {:noreply, socket}

  # =============================================
  # RENDER
  # =============================================

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <.admin_user_nav current_page={@current_page} current_user={@current_user} />

      <div class="flex mb-14">
        <%!-- ============================================ --%>
        <%!-- MOBILE OVERLAY --%>
        <%!-- ============================================ --%>

        <div
          :if={@sidebar_open}
          class="fixed inset-0 z-20 bg-black/60 backdrop-blur-sm lg:hidden"
          phx-click="toggle-sidebar"
        />

        <%!-- ============================================ --%>
        <%!-- LEFT SIDEBAR --%>
        <%!-- ============================================ --%>

        <.admin_sidebar
          active={:profile}
          current_user={@current_user}
          sidebar_open={@sidebar_open}
          draft_count={@draft_count}
        />

        <%!-- ============================================ --%>
        <%!-- MAIN CONTENT --%>
        <%!-- ============================================ --%>

        <div class="flex-1 flex flex-col min-w-0">
          <.mobile_topbar
            active_tab={@active_tab}
            on_toggle="toggle-sidebar"
          />

          <div class="flex-1 overflow-y-auto p-6 border border-gray-700 rounded-xl shadow-xl ">
            <div class="mb-6">
              <h1 class="text-lg font-semibold text-white">Profile</h1>
            </div>

            <div class="max-w-lg space-y-4">
              <%!-- ============================================ --%>
              <%!-- PROFILE CARD--%>
              <%!-- ============================================ --%>

              <div class="border border-gray-800 rounded-xl p-6 bg-gray-900/20">
                <div class="flex items-center gap-4 mb-6 pb-6 border-b border-gray-800">
                  <div class="w-16 h-16 rounded-full bg-gradient-to-br from-[#fedf16] to-amber-500 flex items-center justify-center shrink-0">
                    <span class="text-black text-2xl font-black">
                      {String.first(@current_user.username) |> String.upcase()}
                    </span>
                  </div>
                  <div>
                    <p class="text-white font-semibold text-base">{@current_user.username}</p>
                    <p class="text-gray-500 text-sm">{@current_user.email}</p>
                    <span class="inline-flex items-center gap-1 text-xs bg-[#fedf16]/10 text-[#fedf16] border border-[#fedf16]/20 px-2 py-0.5 rounded-full font-medium mt-1.5">
                      <.icon name="hero-shield-check" class="w-3 h-3" />
                      {String.capitalize(to_string(@current_user.role))}
                    </span>
                  </div>
                </div>

                <div class="space-y-4">
                  <.profile_row icon="hero-envelope" label="Email" value={@current_user.email} />
                  <.profile_row icon="hero-user" label="Username" value={@current_user.username} />
                  <.profile_row
                    icon="hero-calendar"
                    label="Bergabung"
                    value={Calendar.strftime(@current_user.inserted_at, "%d %B %Y")}
                  />
                  <.profile_row
                    icon="hero-identification"
                    label="Provider"
                    value={@current_user.provider || "Email & Password"}
                  />
                  <.profile_row
                    icon="hero-check-badge"
                    label="Status"
                    value={
                      if @current_user.confirmed_at, do: "Terverifikasi", else: "Belum diverifikasi"
                    }
                  />
                </div>
              </div>

              <%!-- ============================================ --%>
              <%!-- STATS CARD--%>
              <%!-- ============================================ --%>

              <div class="border border-gray-800 rounded-xl p-5 bg-gray-900/20">
                <p class="text-xs font-semibold text-gray-600 uppercase tracking-wider mb-4">
                  Statistik
                </p>
                <div class="grid grid-cols-2 gap-4">
                  <div class="text-center p-3 rounded-lg bg-gray-800/50">
                    <p class="text-2xl font-bold text-white">{@total_articles}</p>
                    <p class="text-xs text-gray-500 mt-1">Total Artikel</p>
                  </div>
                  <div class="text-center p-3 rounded-lg bg-amber-500/5 border border-amber-500/20">
                    <p class="text-2xl font-bold text-amber-400">{@draft_count}</p>
                    <p class="text-xs text-gray-500 mt-1">Draft Tersimpan</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # =============================================
  # HANDLE EVENT
  # =============================================

  @impl true
  def handle_event("toggle-sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  # =============================================
  # PRIVATE HELPER
  # =============================================

  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :value, :string, required: true

  defp profile_row(assigns) do
    ~H"""
    <div class="flex items-center gap-3">
      <div class="w-8 h-8 rounded-lg bg-gray-800 flex items-center justify-center shrink-0">
        <.icon name={@icon} class="w-4 h-4 text-gray-500" />
      </div>
      <div>
        <p class="text-xs text-gray-600">{@label}</p>
        <p class="text-sm text-gray-200">{@value}</p>
      </div>
    </div>
    """
  end
end

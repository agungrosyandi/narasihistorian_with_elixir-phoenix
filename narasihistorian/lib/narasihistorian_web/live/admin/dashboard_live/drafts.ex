defmodule NarasihistorianWeb.Admin.DashboardLive.Drafts do
  use NarasihistorianWeb, :live_view
  alias Narasihistorian.Drafts

  import NarasihistorianWeb.CustomComponents,
    only: [admin_sidebar: 1, admin_user_nav: 1, mobile_topbar: 1]

  # =============================================
  # MOUNT
  # =============================================

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_user.role == :admin do
      page_title = "Drafts"
      draft_count = length(Drafts.list_all_drafts())

      {:ok,
       socket
       |> assign(:page_title, page_title)
       |> assign(:current_page, :dashboard)
       |> assign(:sidebar_open, false)
       |> assign(:active_tab, :drafts)
       |> assign(:draft_count, draft_count)}
    else
      {:ok, socket |> put_flash(:error, "Akses ditolak") |> redirect(to: ~p"/")}
    end
  end

  # =============================================
  # RENDER
  # =============================================

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <.admin_user_nav current_page={@current_page} current_user={@current_user} />

      <div class="flex flex-row mb-14">
        <div
          :if={@sidebar_open}
          class="fixed inset-0 z-20 bg-black/60 backdrop-blur-sm lg:hidden"
          phx-click="toggle-sidebar"
        />

        <.admin_sidebar
          active={:drafts}
          current_user={@current_user}
          sidebar_open={@sidebar_open}
          draft_count={@draft_count}
        />

        <div class="flex-1 flex flex-col min-w-0 ">
          <.mobile_topbar active_tab={@active_tab} on_toggle="toggle-sidebar" />

          <div class="flex-1 overflow-y-auto p-6 border border-gray-700 rounded-xl shadow-xl ">
            <div class="mb-6">
              <h1 class="text-lg font-semibold text-white">Draft Tersimpan</h1>
              <p class="text-sm text-gray-500 mt-0.5">Semua draft dari semua pengguna</p>
            </div>

            <.live_component
              module={NarasihistorianWeb.Admin.DashboardLive.DraftsPanelComponent}
              id="drafts-panel"
              current_user={@current_user}
            />
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
end

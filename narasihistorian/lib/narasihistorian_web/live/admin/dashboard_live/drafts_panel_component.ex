defmodule NarasihistorianWeb.Admin.DashboardLive.DraftsPanelComponent do
  @moduledoc """
  Dashboard panel showing all pending drafts from all users.
  render with:

      <.live_component
        module={NarasihistorianWeb.Admin.DraftsPanelComponent}
        id="drafts-panel"
        current_user={@current_user}
      />
  """
  use NarasihistorianWeb, :live_component

  alias Narasihistorian.Drafts
  import NarasihistorianWeb.Admin.DashboardLive.DraftHelpers

  @impl true
  def update(assigns, socket) do
    drafts = Drafts.list_all_drafts()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:drafts, drafts)
     |> assign(:confirm_delete_id, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="border border-gray-600 rounded-lg">
      <%!-- ----------------------- --%>
      <%!-- PANEL HEADER --%>
      <%!-- ----------------------- --%>

      <div class="flex items-center justify-between px-4 py-3 border-b border-gray-600">
        <div class="flex items-center gap-2">
          <.icon name="hero-clock" class="w-4 h-4 text-amber-400" />
          <h2 class="text-sm font-semibold text-gray-100">Draft Tersimpan</h2>
          <span
            :if={length(@drafts) > 0}
            class="text-xs bg-amber-400/20 text-amber-400 rounded-full px-2 py-0.5"
          >
            {length(@drafts)}
          </span>
        </div>
      </div>

      <%!-- ----------------------- --%>
      <%!-- EMPTY STATE --%>
      <%!-- ----------------------- --%>

      <div :if={@drafts == []} class="px-4 py-8 text-center text-gray-500 text-sm">
        <.icon name="hero-document-text" class="w-8 h-8 mx-auto mb-2 opacity-40" />
        <p>Belum ada draft tersimpan</p>
      </div>

      <%!-- ----------------------- --%>
      <%!-- DRAFT LIST --%>
      <%!-- ----------------------- --%>

      <div :if={@drafts != []} class="divide-y divide-gray-700">
        <%= for draft <- @drafts do %>
          <div class="flex flex-col gap-5 px-4 py-3 hover:bg-gray-800/50 transition-colors md:flex-row md:items-center">
            <%!-- ----------------------- --%>
            <%!-- TYPE ICON --%>
            <%!-- ----------------------- --%>

            <div class="shrink-0">
              <span class={[
                "inline-flex items-center justify-center w-8 h-8 rounded-lg text-xs font-bold",
                if(draft.draft_type == "category",
                  do: "bg-blue-500/20 text-blue-400",
                  else: "bg-purple-500/20 text-purple-400"
                )
              ]}>
                {if draft.draft_type == "category", do: "KAT", else: "ART"}
              </span>
            </div>

            <%!-- ----------------------- --%>
            <%!-- DRAFT INFO --%>
            <%!-- ----------------------- --%>

            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2">
                <p class="text-sm font-medium text-gray-100 truncate">
                  {draft_title(draft)}
                </p>
                <span class={[
                  "shrink-0 text-xs px-1.5 py-0.5 rounded",
                  if(draft.action == "new",
                    do: "bg-green-500/20 text-green-400",
                    else: "bg-yellow-500/20 text-yellow-400"
                  )
                ]}>
                  {if draft.action == "new", do: "Baru", else: "Edit"}
                </span>
              </div>
              <div class="flex items-center gap-3 mt-0.5">
                <p class="text-xs text-gray-500 truncate">
                  <.icon name="hero-user" class="w-3 h-3 inline mr-0.5" />
                  {draft.user.username}
                </p>
                <p class="text-xs text-gray-500 shrink-0">
                  {time_ago(draft.updated_at)}
                </p>
              </div>
            </div>

            <%!-- ----------------------- --%>
            <%!-- ACTIONS --%>
            <%!-- ----------------------- --%>

            <div class="shrink-0 flex items-center gap-2">
              <%!-- ----------------------- --%>
              <%!-- CANTINUE EDITING LINK --%>
              <%!-- ----------------------- --%>

              <.link
                navigate={draft_path(draft)}
                class="text-xs text-blue-400 hover:text-blue-300 transition-colors"
              >
                Lanjutkan
              </.link>

              <%!-- ----------------------- --%>
              <%!-- DELETE WITH CONFIRM --%>
              <%!-- ----------------------- --%>

              <button
                :if={@confirm_delete_id != draft.id}
                type="button"
                phx-click="confirm-delete"
                phx-value-id={draft.id}
                phx-target={@myself}
                class="text-xs text-gray-500 hover:text-red-400 transition-colors cursor-pointer"
              >
                <.icon name="hero-trash" class="w-3.5 h-3.5" />
              </button>

              <div :if={@confirm_delete_id == draft.id} class="flex items-center gap-1">
                <button
                  type="button"
                  phx-click="delete-draft"
                  phx-value-id={draft.id}
                  phx-target={@myself}
                  class="text-xs text-red-400 hover:text-red-300 transition-colors cursor-pointer"
                >
                  Hapus
                </button>
                <button
                  type="button"
                  phx-click="cancel-delete"
                  phx-target={@myself}
                  class="text-xs text-gray-500 hover:text-gray-300 transition-colors cursor-pointer"
                >
                  Batal
                </button>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # ============================================================================
  # HANDLE EVENT
  # ============================================================================

  @impl true
  def handle_event("confirm-delete", %{"id" => id}, socket) do
    {:noreply, assign(socket, :confirm_delete_id, String.to_integer(id))}
  end

  def handle_event("cancel-delete", _params, socket) do
    {:noreply, assign(socket, :confirm_delete_id, nil)}
  end

  def handle_event("delete-draft", %{"id" => id}, socket) do
    case Drafts.delete_draft_by_id(String.to_integer(id)) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:drafts, Drafts.list_all_drafts())
         |> assign(:confirm_delete_id, nil)}

      {:error, _} ->
        {:noreply, socket}
    end
  end
end

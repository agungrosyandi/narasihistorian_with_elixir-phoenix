defmodule NarasihistorianWeb.Admin.CategoryLive.Index do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Categories
  alias Narasihistorian.Categories.Category
  alias Narasihistorian.Drafts

  alias NarasihistorianWeb.Admin.CategoryLive.FormComponent

  import NarasihistorianWeb.CustomComponents, only: [admin_user_nav: 1, modal: 1]

  @take_page 1
  @take_per_page 5

  # ============================================================================
  # MOUNT
  # ============================================================================

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_user.role == :admin do
      {:ok,
       socket
       |> assign(:page_title, "Kategori")
       |> assign(:current_page, :categories)
       |> assign(page: @take_page, per_page: @take_per_page)
       |> assign(:end_of_list?, false)
       |> assign(:category, nil)
       |> assign(:draft_id, nil)
       |> assign(:draft_count, 0)
       |> assign(:pending_draft, nil)
       |> stream(:categories, [])
       |> load_categories()
       |> refresh_draft_count()}
    else
      {:ok,
       socket
       |> put_flash(:error, "Akses ke Kategori terbatas hanya untuk admin")
       |> redirect(to: ~p"/")}
    end
  end

  # ============================================================================
  # HANDLE PARAMS
  # ============================================================================

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, params) do
    socket
    |> assign(:page_title, "Buat Kategori")
    |> assign(:category, %Category{})
    |> assign(:draft_id, params["draft_id"])
    |> assign(:pending_draft, nil)
  end

  defp apply_action(socket, :edit, %{"id" => id} = params) do
    socket
    |> assign(:page_title, "Edit Kategori")
    |> assign(:category, Categories.get_category!(id))
    |> assign(:draft_id, params["draft_id"])
    |> assign(:pending_draft, nil)
  end

  defp apply_action(socket, _action, _params) do
    socket
    |> save_pending_draft_to_db()
    |> assign(:page_title, "Kategori")
    |> assign(:category, nil)
    |> assign(:draft_id, nil)
    |> assign(:pending_draft, nil)
    |> refresh_draft_count()
  end

  # ============================================================================
  # HANDLE INFO
  # ============================================================================

  @impl true
  def handle_info(
        {FormComponent, {:saved, _category}},
        socket
      ) do
    {:noreply,
     socket
     |> assign(:pending_draft, nil)
     |> refresh_draft_count()
     |> load_categories()}
  end

  def handle_info(
        {FormComponent, {:form_params, action, ref_id, params}},
        socket
      ) do
    {:noreply, assign(socket, :pending_draft, {action, ref_id, params})}
  end

  # ============================================================================
  # RENDER
  # ============================================================================

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto mb-14">
        <.admin_user_nav current_page={@current_page} current_user={@current_user} />
        <.header>
          <:actions>
            <div class="flex justify-end items-center gap-4 mb-8">
              <.link
                :if={@draft_count > 0}
                navigate={~p"/admin/dashboard/drafts"}
                class="flex items-center gap-1.5 text-xs text-amber-400 bg-amber-400/10 border border-amber-400/30 rounded-full px-3 py-1.5 hover:bg-amber-400/20 transition-colors"
              >
                <.icon name="hero-clock" class="w-3.5 h-3.5" />
                {@draft_count} draft tersimpan
              </.link>
              <.link patch={~p"/admin/categories/new"}>
                <.span_custom variant="transparant">
                  <.icon name="hero-plus" class="w-4 h-4 mb-1 mr-2" /> Buat Kategori
                </.span_custom>
              </.link>
            </div>
          </:actions>
        </.header>

        <div class="border border-gray-600 p-3 rounded-lg overflow-x-auto">
          <.table
            id="categories"
            rows={@streams.categories}
            row_click={fn {_id, category} -> JS.navigate(~p"/admin/categories/#{category}") end}
          >
            <:col :let={{_id, category}} label="No">{category.id}</:col>
            <:col :let={{_id, category}} label="Kategori">{category.category_name}</:col>

            <:action :let={{_id, category}}>
              <.link patch={~p"/admin/categories/#{category}/edit"}>Edit</.link>
            </:action>
            <:action :let={{_id, category}}>
              <.link
                phx-click={JS.push("delete", value: %{id: category.id})}
                data-confirm="Hapus kategori ini?"
              >
                Delete
              </.link>
            </:action>
          </.table>
        </div>

        <div class="flex justify-center mt-6">
          <.button_custom
            :if={!@end_of_list?}
            variant="transparant"
            phx-click="load-more"
            phx-disable-with="Loading..."
          >
            Muat Lebih Banyak
          </.button_custom>
          <p :if={@end_of_list?} class="text-gray-500 text-sm">Semua kategori telah ditampilkan</p>
        </div>
      </div>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="category-modal"
        show
        on_cancel={JS.patch(~p"/admin/categories")}
      >
        <:title><span class="text-white">{@page_title}</span></:title>
        <:body>
          <.live_component
            module={FormComponent}
            id={@category.id || :new}
            action={@live_action}
            category={@category}
            current_user={@current_user}
            navigate={~p"/admin/categories"}
            draft_id={@draft_id}
          />
        </:body>
        <:confirm>
          <button
            type="button"
            onclick={"document.getElementById('submit-#{@category.id || :new}').click()"}
            phx-disable-with="Menyimpan..."
            class="btn btn-outline border-[#fedf16e0] text-xs text-gray-100 hover:bg-[#fedf16e0] hover:text-black px-10"
          >
            <.icon name="hero-inbox-arrow-down" class="w-4 h-4 inline mr-1" />

            {if @live_action == :new, do: "Buat Kategori", else: "Simpan Perubahan"}
          </button>
        </:confirm>
      </.modal>
    </Layouts.app>
    """
  end

  # ============================================================================
  # HANDLE EVENT
  # ============================================================================

  @impl true
  def handle_event("load-more", _params, socket) do
    {:noreply,
     socket
     |> update(:page, &(&1 + 1))
     |> load_categories()}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    category = Categories.get_category!(id)

    case Categories.delete_category(category) do
      {:ok, _} ->
        {:noreply,
         socket
         |> stream_delete(:categories, category)
         |> put_flash(:info, "Kategori berhasil dihapus")}

      {:error, :has_articles} ->
        {:noreply, put_flash(socket, :error, "Hapus artikel yang berkaitan terlebih dahulu")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Gagal menghapus kategori")}
    end
  end

  # ============================================================================
  # PRIVATE HELPER DRAFTT
  # ============================================================================

  defp save_pending_draft_to_db(socket) do
    case socket.assigns.pending_draft do
      nil ->
        socket

      {action, ref_id, params} ->
        if map_has_any_value?(params) do
          user = socket.assigns.current_user

          case Drafts.upsert_draft(user, "category", to_string(action), ref_id, params) do
            {:ok, _} -> put_flash(socket, :info, "Draft tersimpan — lihat di Dashboard → Drafts")
            {:error, _} -> put_flash(socket, :error, "Gagal menyimpan draft")
          end
        else
          socket
        end
    end
  end

  defp map_has_any_value?(params) when is_map(params) do
    params
    |> Enum.reject(fn {k, _v} -> String.starts_with?(k, "_unused_") end)
    |> Enum.any?(fn {_k, v} -> is_binary(v) and String.trim(v) != "" end)
  end

  defp refresh_draft_count(socket) do
    count = Drafts.count_drafts(socket.assigns.current_user.id, "category")

    assign(socket, :draft_count, count)
  end

  # ============================================================================
  # PRIVATE HELPER LOAD CATEGORIES
  # ============================================================================

  defp load_categories(socket) do
    %{page: page, per_page: per_page} = socket.assigns
    categories = Categories.list_categories(page: page, per_page: per_page)

    socket
    |> stream(:categories, categories)
    |> assign(:end_of_list?, length(categories) < per_page)
  end
end

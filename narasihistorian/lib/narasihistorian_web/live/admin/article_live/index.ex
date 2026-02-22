defmodule NarasihistorianWeb.Admin.ArticleLive.Index do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Admin
  alias Narasihistorian.Articles.Article
  alias Narasihistorian.Drafts

  alias NarasihistorianWeb.Admin.ArticleLive.FormComponent

  import NarasihistorianWeb.CustomComponents,
    only: [admin_user_nav: 1, pagination_controls: 1, truncate: 2, quill_plain_text: 1, modal: 1]

  @take_article_per_page 10

  # ============================================================================
  # MOUNT
  # ============================================================================

  @impl true
  def mount(_params, _session, socket) do
    page_title = "Listing Articles"

    socket =
      socket
      |> assign(:page_title, page_title)
      |> assign(:form, to_form(%{}))
      |> assign(:pagination, nil)
      |> assign(:searching, false)
      |> assign(:current_nav, :articles)
      |> assign(:current_page, :articles)
      |> assign(:article, nil)
      |> assign(:draft_id, nil)
      |> assign(:draft_count, 0)
      |> assign(:pending_draft, nil)

    {:ok, socket}
  end

  # ============================================================================
  # HANDLE PARAMS
  # ============================================================================

  @impl true
  def handle_params(params, _uri, %{assigns: %{current_user: current_user}} = socket) do
    socket =
      socket
      |> save_pending_draft_to_db()
      |> apply_action(socket.assigns.live_action, params)

    if socket.assigns.searching do
      send(self(), {:load_articles, params})
      {:noreply, socket}
    else
      pagination = Admin.filter_articles(params, [per_page: @take_article_per_page], current_user)

      socket =
        socket
        |> stream(:articles, pagination.entries, reset: true)
        |> assign(:form, to_form(params))
        |> assign(:pagination, pagination)

      {:noreply, socket}
    end
  end

  defp apply_action(socket, :new, params) do
    socket
    |> assign(:page_title, "Buat Artikel")
    |> assign(:article, %Article{})
    |> assign(:draft_id, params["draft_id"])
    |> assign(:pending_draft, nil)
  end

  defp apply_action(socket, :edit, %{"id" => id} = params) do
    socket
    |> assign(:page_title, "Edit Artikel")
    |> assign(:article, Admin.get_article_with_tags!(id))
    |> assign(:draft_id, params["draft_id"])
    |> assign(:pending_draft, nil)
  end

  defp apply_action(socket, _action, _params) do
    socket
    |> assign(:page_title, "Listing Articles")
    |> assign(:article, nil)
    |> assign(:draft_id, nil)
    |> assign(:pending_draft, nil)
    |> refresh_draft_count()
  end

  # ============================================================================
  # HANDLE INFO
  # ============================================================================

  @impl true
  def handle_info({:load_articles, params}, %{assigns: %{current_user: current_user}} = socket) do
    pagination = Admin.filter_articles(params, [per_page: @take_article_per_page], current_user)

    socket =
      socket
      |> stream(:articles, pagination.entries, reset: true)
      |> assign(:form, to_form(params))
      |> assign(:pagination, pagination)
      |> assign(:searching, false)

    {:noreply, socket}
  end

  def handle_info({FormComponent, {:saved, _article}}, socket) do
    {:noreply,
     socket
     |> assign(:pending_draft, nil)
     |> refresh_draft_count()
     |> push_patch(to: ~p"/admin/articles")}
  end

  def handle_info({FormComponent, {:form_params, action, ref_id, params}}, socket) do
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

        <%!-------------------------%>
        <%!-- HEADER --%>
        <%!-------------------------%>

        <div class="flex justify-end items-center gap-4 mb-8">
          <.link
            :if={@draft_count > 0}
            navigate={~p"/admin/dashboard/drafts"}
            class="flex items-center gap-1.5 text-xs text-amber-400 bg-amber-400/10 border border-amber-400/30 rounded-full px-3 py-1.5 hover:bg-amber-400/20 transition-colors"
          >
            <.icon name="hero-clock" class="w-3.5 h-3.5" />
            {@draft_count} draft tersimpan
          </.link>

          <.link patch={~p"/admin/articles/new"}>
            <.span_custom variant="transparant">
              <.icon name="hero-plus" class="w-4 h-4 mb-1 mr-2" /> Buat Artikel
            </.span_custom>
          </.link>
        </div>

        <%!-------------------------%>
        <%!-- FILTER & SEARCH --%>
        <%!-------------------------%>

        <div class="relative mb-6 items-center">
          <.form class="flex flex-row gap-5" for={@form} id="filter-form" phx-change="filter">
            <.input
              field={@form[:q]}
              placeholder="Search ...."
              autocomplete="off"
              phx-debounce="500"
            />

            <.input
              type="select"
              field={@form[:sort_by]}
              prompt="Sort By"
              options={[
                Latest: "inserted_at_desc",
                Oldest: "inserted_at_asc",
                "A to Z": "article_name_asc",
                "Z to A": "article_name_desc",
                "Author A-Z": "author_asc",
                "Author Z-A": "author_desc"
              ]}
            />

            <.link class="px-3 py-2 hover:underline" patch={~p"/admin/articles"}>
              Reset
            </.link>
          </.form>
        </div>

        <%!-------------------------%>
        <%!-- LOADING AND TABLE --%>
        <%!-------------------------%>

        <%= cond do %>
          <% @searching -> %>
            <div class="text-center py-12">
              <span class="loading loading-spinner loading-lg"></span>
              <p class="mt-4 text-gray-600">Searching articles...</p>
            </div>
          <% @pagination == nil -> %>
            <div class="text-center py-12">
              <span class="loading loading-spinner loading-lg"></span>
              <p class="mt-4 text-gray-600">Loading articles...</p>
            </div>
          <% @pagination && @pagination.entries == [] -> %>
            <div class="alert alert-info max-w-2xl mx-auto">
              <.icon name="hero-information-circle" class="w-5 h-5" />
              <span>No articles found matching your search</span>
            </div>
          <% true -> %>
            <div class="border border-gray-600 p-3 rounded-lg overflow-x-auto">
              <.table id="articles" rows={@streams.articles}>
                <:col :let={{_id, article}} label="Judul Artikel">
                  <.link navigate={~p"/articles/#{article.id}"}>
                    {truncate(article.article_name, 30)}
                  </.link>
                </:col>

                <:col :let={{_id, article}} label="Konten">
                  {truncate(quill_plain_text(article.content), 20)}...
                </:col>

                <:col :let={{_id, article}} label="Penulis">
                  {display_author(article)}
                </:col>

                <:col :let={{_id, article}} label="Created">
                  {Calendar.strftime(article.inserted_at, "%d %b %Y %H:%M")}
                </:col>

                <:col :let={{_id, article}} label="Last Update">
                  {Calendar.strftime(article.updated_at, "%d %b %Y %H:%M")}
                </:col>

                <:action :let={{_id, article}}>
                  <.link patch={~p"/admin/articles/#{article.id}/edit"}>Edit</.link>
                </:action>

                <:action :let={{id, article}}>
                  <.link
                    phx-click={JS.push("delete", value: %{id: article.id}) |> hide("##{id}")}
                    data-confirm="Kamu yakin ingin menghapus artikel ?"
                  >
                    Delete
                  </.link>
                </:action>
              </.table>
            </div>

            <%= if @pagination do %>
              <.pagination_controls
                pagination={@pagination}
                params={@form.params}
                base_path={~p"/admin/articles"}
              />
            <% end %>
        <% end %>
      </div>

      <%!-------------------------%>
      <%!-- MODAL --%>
      <%!-------------------------%>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="article-modal"
        show
        on_cancel={JS.patch(~p"/admin/articles")}
      >
        <:title><span class="text-white">{@page_title}</span></:title>
        <:body>
          <.live_component
            module={FormComponent}
            id={@article.id || :new}
            action={@live_action}
            article={@article}
            current_user={@current_user}
            navigate={~p"/admin/articles"}
            draft_id={@draft_id}
          />
        </:body>
        <:confirm>
          <button
            type="button"
            onclick={"document.getElementById('submit-#{@article.id || :new}').click()"}
            phx-disable-with="Menyimpan..."
            class="btn btn-outline border-[#fedf16e0] text-xs text-gray-100 hover:bg-[#fedf16e0] hover:text-black px-10"
          >
            <.icon name="hero-inbox-arrow-down" class="w-4 h-4 inline mr-1" />
            {if @live_action == :new, do: "Buat Artikel", else: "Simpan Perubahan"}
          </button>
        </:confirm>
      </.modal>
    </Layouts.app>
    """
  end

  # ============================================================================
  # HANDLE EVENT
  # ============================================================================

  def handle_event("filter", params, socket) do
    params =
      params
      |> Map.take(~w(q sort_by))
      |> Map.reject(fn {_, v} -> v == "" end)
      |> Map.put("page", "1")

    socket =
      socket
      |> assign(:searching, true)
      |> push_patch(to: ~p"/admin/articles?#{params}")

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_user: current_user}} = socket) do
    id = if is_binary(id), do: String.to_integer(id), else: id
    article = Admin.get_article!(id)

    case Admin.delete_article(article, current_user) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Article deleted successfully!")
         |> stream_delete(:articles, article)}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You don't have permission to delete this article")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete article")}
    end
  end

  # ============================================================================
  # PRIVATE HELPER DRAFT
  # ============================================================================

  defp save_pending_draft_to_db(socket) do
    case socket.assigns.pending_draft do
      nil ->
        socket

      {action, ref_id, params} ->
        if map_has_any_value?(params) do
          user = socket.assigns.current_user

          case Drafts.upsert_draft(user, "article", to_string(action), ref_id, params) do
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
    count = Drafts.count_drafts(socket.assigns.current_user.id, "article")
    assign(socket, :draft_count, count)
  end

  # ============================================================================
  # PRIVATE HELPER DISPLAY AUTHOR
  # ============================================================================

  defp display_author(article) do
    case article.user do
      %{username: username} -> username
      _ -> "Unknown"
    end
  end
end

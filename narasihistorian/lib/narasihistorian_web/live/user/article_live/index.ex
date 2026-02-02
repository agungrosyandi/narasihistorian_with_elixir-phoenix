defmodule NarasihistorianWeb.User.ArticleLive.Index do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Admin

  # ============================================================================
  # MOUNT
  # ============================================================================

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Manage Artikel")
      |> assign(:form, to_form(%{}))
      |> assign(:pagination, nil)
      |> assign(:searching, false)

    {:ok, socket}
  end

  # ============================================================================
  # HANDLE PARAMS
  # ============================================================================

  @impl true
  def handle_params(params, _uri, socket) do
    current_user = socket.assigns.current_user

    if socket.assigns.searching do
      send(self(), {:load_articles, params})
      {:noreply, socket}
    else
      pagination = Admin.filter_articles(params, [per_page: 10], current_user)

      socket =
        socket
        |> stream(:articles, pagination.entries, reset: true)
        |> assign(:form, to_form(params))
        |> assign(:pagination, pagination)

      {:noreply, socket}
    end
  end

  # ============================================================================
  # HANDLE INFO
  # ============================================================================

  @impl true
  def handle_info({:load_articles, params}, socket) do
    current_user = socket.assigns.current_user
    pagination = Admin.filter_articles(params, [per_page: 10], current_user)

    socket =
      socket
      |> stream(:articles, pagination.entries, reset: true)
      |> assign(:form, to_form(params))
      |> assign(:pagination, pagination)
      |> assign(:searching, false)

    {:noreply, socket}
  end

  # ============================================================================
  # HANDLE EVENT
  # ============================================================================

  @impl true
  def handle_event("filter", params, socket) do
    params =
      params
      |> Map.take(~w(q sort_by))
      |> Map.reject(fn {_, v} -> v == "" end)
      |> Map.put("page", "1")

    socket =
      socket
      |> assign(:searching, true)
      |> push_patch(to: ~p"/user/articles?#{params}")

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    current_user = socket.assigns.current_user
    id = if is_binary(id), do: String.to_integer(id), else: id
    article = Admin.get_article!(id)

    case Admin.delete_article(article, current_user) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Article deleted successfully!")
         |> stream_delete(:articles, article)}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You don't have permission to delete this article")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete article")}
    end
  end

  # ============================================================================
  # RENDER
  # ============================================================================

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto mb-14">
        <%!-- Header --%>

        <div class="flex justify-end items-start mb-8">
          <div class="flex gap-2">
            <.link navigate={~p"/user/dashboard"} class="btn btn-ghost">
              <.icon name="hero-arrow-uturn-left" class="w-4 h-4 mr-1 text-gray-400" />Main Dashboard
            </.link>
            <.link navigate={~p"/user/articles/new"} class="btn btn-primary">
              <.icon name="hero-plus" class="w-4 h-4 mr-1 text-gray-800" /> New Article
            </.link>
          </div>
        </div>

        <%!-- Search & Filter --%>

        <div class="mb-6 flex flex-row">
          <.form
            class="flex flex-col md:flex-row gap-4 w-full justify-between"
            for={@form}
            id="filter-form"
            phx-change="filter"
          >
            <div class="w-full">
              <.input
                field={@form[:q]}
                placeholder="Search your articles..."
                autocomplete="off"
                phx-debounce="500"
              />
            </div>

            <div class="flex flex-row items-center gap-3 justify-start">
              <.input
                type="select"
                field={@form[:sort_by]}
                prompt="Sort By"
                options={[
                  Latest: "inserted_at_asc",
                  Oldest: "inserted_at_desc",
                  "A to Z": "article_name_asc",
                  "Z to A": "article_name_desc"
                ]}
              />

              <.link class="hover:text-[#fedf16e0]" patch={~p"/user/articles"}>
                Reset
              </.link>
            </div>
          </.form>
        </div>

        <%!-- Loading States & Table --%>

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
            <div class="card bg-base-200">
              <div class="card-body text-center py-12">
                <.icon name="hero-clipboard-document" class="w-16 h-16 mx-auto mb-4 text-gray-400" />
                <h3 class="text-xl font-semibold mb-2">No articles found</h3>
                <p class="text-gray-400 mb-4">
                  <%= if @form.params["q"] do %>
                    Pencarianmu Tidak Ditemukan
                  <% end %>
                </p>
              </div>
            </div>
          <% true -> %>
            <div class="border border-gray-600 p-3 rounded-lg overflow-x-auto">
              <.table id="articles" rows={@streams.articles}>
                <:col :let={{_id, article}} label="Title">
                  <div class="flex items-center gap-3">
                    <div class="flex-1">
                      <.link
                        navigate={~p"/articles/#{article.id}"}
                        class="font-semibold hover:text-primary transition-colors"
                      >
                        {article.article_name}
                      </.link>
                      <div class="text-sm text-gray-400 mt-3">
                        {article.content |> quill_plain_text() |> String.slice(0, 80)}...
                      </div>
                    </div>
                  </div>
                </:col>

                <:col :let={{_id, article}} label="Status">
                  <div class={"badge p-4 font-bold " <> status_badge_class(article.status)}>
                    {article.status}
                  </div>
                </:col>

                <:col :let={{_id, article}} label="Views">
                  <div class="flex items-center gap-1 text-gray-200">
                    <.icon name="hero-eye" class="w-4 h-4 mr-1 text-gray-400" />
                    {article.view_count}
                  </div>
                </:col>

                <:col :let={{_id, article}} label="Last Updated">
                  {Calendar.strftime(article.updated_at, "%b %d, %Y")}
                </:col>

                <:action :let={{_id, article}}>
                  <.link navigate={~p"/user/articles/#{article.id}/edit"} class="link link-primary">
                    Edit
                  </.link>
                </:action>

                <:action :let={{id, article}}>
                  <.link
                    phx-click={JS.push("delete", value: %{id: article.id}) |> hide("##{id}")}
                    data-confirm="Are you sure you want to delete this article?"
                    class="link link-error"
                  >
                    Delete
                  </.link>
                </:action>
              </.table>
            </div>

            <%!-- Pagination --%>

            <%= if @pagination do %>
              <.pagination_controls pagination={@pagination} params={@form.params} />
            <% end %>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  # ============================================================================
  # PAGINATION CONTROLS
  # ============================================================================

  def pagination_controls(assigns) do
    ~H"""
    <div class="flex items-center justify-between mt-6">
      <div class="text-sm text-gray-400">
        Showing {(@pagination.page - 1) * @pagination.per_page + 1} to {min(
          @pagination.page * @pagination.per_page,
          @pagination.total_count
        )} of {@pagination.total_count} results
      </div>

      <div class="join">
        <%= if @pagination.page > 1 do %>
          <.link
            patch={build_pagination_path(@params, @pagination.page - 1)}
            class="join-item btn btn-sm"
          >
            «
          </.link>
        <% else %>
          <button class="join-item btn btn-sm btn-disabled">«</button>
        <% end %>

        <%= for page <- pagination_range(@pagination) do %>
          <%= if page == @pagination.page do %>
            <button class="join-item btn btn-sm btn-active">{page}</button>
          <% else %>
            <.link patch={build_pagination_path(@params, page)} class="join-item btn btn-sm">
              {page}
            </.link>
          <% end %>
        <% end %>

        <%= if @pagination.page < @pagination.total_pages do %>
          <.link
            patch={build_pagination_path(@params, @pagination.page + 1)}
            class="join-item btn btn-sm"
          >
            »
          </.link>
        <% else %>
          <button class="join-item btn btn-sm btn-disabled">»</button>
        <% end %>
      </div>
    </div>
    """
  end

  # ============================================================================
  # PRIVATE HELPER
  # ============================================================================

  defp build_pagination_path(params, page) do
    new_params = Map.put(params || %{}, "page", to_string(page))
    ~p"/user/articles?#{new_params}"
  end

  defp pagination_range(pagination) do
    total_pages = pagination.total_pages
    current_page = pagination.page

    cond do
      total_pages <= 7 -> 1..total_pages
      current_page <= 4 -> 1..7
      current_page >= total_pages - 3 -> (total_pages - 6)..total_pages
      true -> (current_page - 3)..(current_page + 3)
    end
  end

  defp quill_plain_text(nil), do: ""

  defp quill_plain_text(html) do
    html
    |> String.replace(~r/<br\s*\/?>/i, " ")
    |> String.replace(~r/<\/p>/i, " ")
    |> String.replace(~r/<[^>]*>/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp status_badge_class("published"), do: "badge-success"
  defp status_badge_class("draft"), do: "badge-warning"
  defp status_badge_class(_), do: "badge-ghost"
end

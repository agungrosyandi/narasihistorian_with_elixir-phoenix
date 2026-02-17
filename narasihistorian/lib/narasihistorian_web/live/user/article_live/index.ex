defmodule NarasihistorianWeb.User.ArticleLive.Index do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Admin

  alias Narasihistorian.Dashboard

  @number_per_page_pagination_offset 5

  # ============================================================================
  # MOUNT
  # ============================================================================

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "List Artikel")
      |> assign(:form, to_form(%{}))
      |> assign(:pagination, nil)
      |> assign(:searching, false)

    {:ok, socket}
  end

  # ============================================================================
  # HANDLE PARAMS
  # ============================================================================

  @impl true
  def handle_params(params, _uri, %{assigns: %{current_user: current_user}} = socket) do
    if socket.assigns.searching do
      send(self(), {:load_articles, params})
      {:noreply, socket}
    else
      pagination =
        Admin.filter_articles(
          params,
          [per_page: @number_per_page_pagination_offset],
          current_user
        )

      pagination_entries = pagination.entries

      socket =
        socket
        |> stream(:articles, pagination_entries, reset: true)
        |> assign(:form, to_form(params))
        |> assign(:pagination, pagination)

      {:noreply, socket}
    end
  end

  # ============================================================================
  # HANDLE INFO
  # ============================================================================

  @impl true
  def handle_info({:load_articles, params}, %{assigns: %{current_user: current_user}} = socket) do
    pagination =
      Admin.filter_articles(params, [per_page: @number_per_page_pagination_offset], current_user)

    pagination_entries = pagination.entries

    socket =
      socket
      |> stream(:articles, pagination_entries, reset: true)
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
        <%!-------------------------%>
        <%!-- HEADER --%>
        <%!-------------------------%>

        <.main_title_div>
          <.back_link
            navigate={~p"/user/dashboard"}
            icon="hero-arrow-left"
          />
          <.span_custom variant="main-title">{@page_title}</.span_custom>
        </.main_title_div>

        <%!-------------------------%>
        <%!-- SEARCH & FILTER--%>
        <%!-------------------------%>

        <div class="flex flex-col justify-between mb-5 items-start gap-5 md:flex-row md:items-center">
          <.link navigate={~p"/user/articles/new"}>
            <.span_custom variant="yellow">
              <.icon name="hero-plus" class="w-4 h-4 mr-1 text-gray-100" /> Buat Artikel
            </.span_custom>
          </.link>

          <.form
            class="flex flex-col md:flex-row gap-1 w-full md:w-auto"
            for={@form}
            id="filter-form"
            phx-change="filter"
          >
            <.input
              field={@form[:q]}
              placeholder="Search your articles..."
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
                "Z to A": "article_name_desc"
              ]}
            />
          </.form>
        </div>

        <%!-------------------------%>
        <%!-- LOADING STATES & TABLE --%>
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
            <div class="card bg-base-200">
              <div class="card-body text-center py-12">
                <.icon name="hero-clipboard-document" class="w-16 h-16 mx-auto mb-4 text-gray-400" />
                <h3 class="text-xl font-semibold mb-2">Artikel tidak ditemukan</h3>
                <p class="text-gray-400 mb-4">
                  <%= if @form.params["q"] do %>
                    Pencarianmu Tidak Ditemukan
                  <% end %>
                </p>
              </div>
            </div>
          <% true -> %>
            <%!-------------------------%>
            <%!-- TABLE FOUND --%>
            <%!-------------------------%>

            <div class="border border-gray-600 p-3 rounded-lg overflow-x-auto">
              <.table id="articles" rows={@streams.articles}>
                <:col :let={{_id, article}} label="Title">
                  <div class="flex items-center gap-3">
                    <div class="flex-1">
                      <.link
                        navigate={~p"/articles/#{article.id}"}
                        class="font-semibold hover:text-primary transition-colors"
                      >
                        {truncate(article.article_name, 30)}
                      </.link>
                      <div class="text-sm text-gray-400 mt-3">
                        {article.content |> quill_plain_text() |> String.slice(0, 30)}...
                      </div>
                    </div>
                  </div>
                </:col>

                <:col :let={{_id, article}} label="Status">
                  <div class={"badge p-4 font-bold text-sm " <> status_badge_class(article.status)}>
                    {article.status}
                  </div>
                </:col>

                <:col :let={{_id, article}} label="Views">
                  <div class="flex items-center gap-1 text-gray-200">
                    <.icon name="hero-eye" class="w-4 h-4 mr-1 text-gray-400" />
                    {Dashboard.get_article_total_views(article.id)}
                  </div>
                </:col>

                <:col :let={{_id, article}} label="Created">
                  {Calendar.strftime(article.inserted_at, "%b %d, %Y")}
                </:col>

                <:col :let={{_id, article}} label="Updated">
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

            <%!-------------------------%>
            <%!-- PAGINATION --%>
            <%!-------------------------%>

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

  defp truncate(text, length) when is_binary(text) do
    if String.length(text) > length do
      String.slice(text, 0, length) <> "..."
    else
      text
    end
  end

  defp truncate(nil, _length), do: ""

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

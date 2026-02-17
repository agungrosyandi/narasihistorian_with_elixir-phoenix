defmodule NarasihistorianWeb.Admin.ArticleLive.Index do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Admin

  import NarasihistorianWeb.CustomComponents, only: [admin_user_nav: 1]

  @take_article_per_page 10

  # ============================================================================
  # MOUNT
  # ============================================================================

  @impl true
  def mount(_params, _session, socket) do
    # IO.inspect(self(), label: "MOUNT")

    socket =
      socket
      |> assign(:page_title, "Listing Articles")
      |> assign(:form, to_form(%{}))
      |> assign(:pagination, nil)
      |> assign(:searching, false)
      |> assign(:current_nav, :articles)
      |> assign(:current_page, :articles)

    {:ok, socket}
  end

  # ============================================================================
  # RENDER
  # ============================================================================

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <%!-- <% IO.inspect(self(), label: "RENDER (HEEX)") %> --%>

      <div class="container mx-auto mb-14">
        <%!-------------------------%>
        <%!-- ADMIN NAVIGATION --%>
        <%!-------------------------%>

        <.admin_user_nav current_page={@current_page} current_user={@current_user} />

        <%!-------------------------%>
        <%!-- HEADER --%>
        <%!-------------------------%>

        <div class="flex justify-end mb-8">
          <.link navigate={~p"/admin/articles/new"}>
            <.span_custom variant="transparant">
              <.icon name="hero-plus" class="w-4 h-4 mb-1 mr-2" /> Buat Artikel
            </.span_custom>
          </.link>
        </div>

        <%!-------------------------%>
        <%!-- SEARCH --%>
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
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                class="stroke-current shrink-0 w-6 h-6"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              <span>No articles found matching your search</span>
            </div>
          <% true -> %>
            <div class="border border-gray-600 p-3 rounded-lg overflow-x-auto">
              <.table id="articles" rows={@streams.articles}>
                <:col :let={{_id, article}} label="Name">
                  <.link navigate={~p"/articles/#{article.id}"}>
                    {truncate(article.article_name, 30)}
                  </.link>
                </:col>

                <:col :let={{_id, article}} label="Content">
                  {article.content |> quill_plain_text() |> String.slice(0, 50)}...
                </:col>

                <:col :let={{_id, article}} label="Author">
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

            <%!-------------------------%>
            <%!-- PAGIANATION --%>
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
  # HANDLE PARAMS
  # ============================================================================

  @impl true
  def handle_params(params, _uri, %{assigns: %{current_user: current_user}} = socket) do
    # IO.inspect(self(), label: "HANDLE PARAMS")

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

  # ============================================================================
  # HANDLE INFO
  # ============================================================================

  @impl true
  def handle_info({:load_articles, params}, %{assigns: %{current_user: current_user}} = socket) do
    # IO.inspect(self(), label: "HANDLE INFO")

    pagination = Admin.filter_articles(params, [per_page: @take_article_per_page], current_user)

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
        {:noreply,
         socket
         |> put_flash(:error, "You don't have permission to delete this article")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to delete article")}
    end
  end

  # ============================================================================
  # PAGINATION CONTROL COMPONENT
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
  # QUILL TEXT EDITOR
  # ============================================================================

  def quill_plain_text(nil), do: ""

  def quill_plain_text(html) do
    html
    |> String.replace(~r/<br\s*\/?>/i, " ")
    |> String.replace(~r/<\/p>/i, " ")
    |> String.replace(~r/<[^>]*>/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  # ============================================================================
  # PRIVATE HELPER PAGINATION
  # ============================================================================

  defp build_pagination_path(params, page) do
    new_params = Map.put(params || %{}, "page", to_string(page))
    ~p"/admin/articles?#{new_params}"
  end

  defp pagination_range(pagination) do
    total_pages = pagination.total_pages
    current_page = pagination.page

    cond do
      total_pages <= 7 ->
        1..total_pages

      current_page <= 4 ->
        1..7

      current_page >= total_pages - 3 ->
        (total_pages - 6)..total_pages

      true ->
        (current_page - 3)..(current_page + 3)
    end
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

  # ============================================================================
  # PRIVATE HELPER TRUNCATE TEXT
  # ============================================================================

  defp truncate(text, length) when is_binary(text) do
    if String.length(text) > length do
      String.slice(text, 0, length) <> "..."
    else
      text
    end
  end

  defp truncate(nil, _length), do: ""
end

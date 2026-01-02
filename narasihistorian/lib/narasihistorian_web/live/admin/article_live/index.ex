defmodule NarasihistorianWeb.Admin.ArticleLive.Index do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Admin

  # MOUNT ---------------------------------------------------------------------------------

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Listing Articles")
      |> assign(:form, to_form(%{}))
      |> assign(:pagination, nil)
      |> assign(:searching, false)

    {:ok, socket}
  end

  # PARAMS ------------------------------------------------------------------------------------

  @impl true
  def handle_params(params, _uri, socket) do
    # If we're searching, load asynchronously to show loading state
    if socket.assigns.searching do
      send(self(), {:load_articles, params})
      {:noreply, socket}
    else
      # Normal page load or pagination - load immediately
      pagination = Admin.filter_articles(params, per_page: 10)

      socket =
        socket
        |> stream(:articles, pagination.entries, reset: true)
        |> assign(:form, to_form(params))
        |> assign(:pagination, pagination)

      {:noreply, socket}
    end
  end

  # HANDLE INFO ---------------------------------------------------------------------------

  @impl true
  def handle_info({:load_articles, params}, socket) do
    pagination = Admin.filter_articles(params, per_page: 10)

    socket =
      socket
      |> stream(:articles, pagination.entries, reset: true)
      |> assign(:form, to_form(params))
      |> assign(:pagination, pagination)
      |> assign(:searching, false)

    {:noreply, socket}
  end

  # HANDEL EVENT FILTER & DELETE ---------------------------------------------------------------

  def handle_event("filter", params, socket) do
    params =
      params
      |> Map.take(~w(q sort_by))
      |> Map.reject(fn {_, v} -> v == "" end)
      # Reset to page 1 when searching

      |> Map.put("page", "1")

    socket =
      socket
      |> assign(:searching, true)
      |> push_patch(to: ~p"/admin/articles?#{params}")

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    article = Admin.get_article!(id)
    {:ok, _} = Admin.delete_article(article)

    # Refresh the current page after deletion

    params = socket.assigns.form.params
    socket = push_patch(socket, to: ~p"/admin/articles?#{params}")

    {:noreply, socket}
  end

  # PAGINATION CONTROL -----------------------------------------------------------------

  def pagination_controls(assigns) do
    ~H"""
    <div class="flex items-center justify-between mt-6">
      <div class="text-sm text-gray-700">
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

  # QUILL RICH TEXT EDITOR -------------------------------------------

  def quill_plain_text(nil), do: ""

  def quill_plain_text(html) do
    html
    |> String.replace(~r/<br\s*\/?>/i, " ")
    |> String.replace(~r/<\/p>/i, " ")
    |> String.replace(~r/<[^>]*>/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  # PRIVATE HELPER --------------------------------------------------------

  # Helper function to build pagination path with existing params

  defp build_pagination_path(params, page) do
    new_params = Map.put(params || %{}, "page", to_string(page))
    ~p"/admin/articles?#{new_params}"
  end

  # Helper to generate page range for pagination

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

  # Helper to truncate paragrapgh

  defp truncate(nil, _length), do: ""

  defp truncate(text, length) do
    if String.length(text) > length do
      String.slice(text, 0, length) <> "..."
    else
      text
    end
  end
end

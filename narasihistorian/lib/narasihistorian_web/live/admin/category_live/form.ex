defmodule NarasihistorianWeb.Admin.CategoryLive.Form do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Categories
  alias Narasihistorian.Categories.Category

  # ============================================================================
  # MOUNT
  # ============================================================================

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  # ============================================================================
  # RENDER
  # ============================================================================

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="relative flex w-full flex-col gap-3 mb-10 lg:min-h-[70vh] lg:flex-row shadow-lg">
        <div class=" w-[100%] lg:block flex-1">
          <img
            class="relative h-full w-full object-cover rounded-lg"
            src="/images/new-bg-1.jpg"
            alt="My Image"
          />
        </div>

        <div class="flex flex-col flex-1 p-8 border border-gray-700 rounded-lg">
          <.header>
            {@page_title}
          </.header>

          <.form for={@form} id="category-form" phx-change="validate" phx-submit="save">
            <.input field={@form[:category_name]} type="text" label="Nama Kategori" />
            <.input field={@form[:slug]} type="text" label="Slug" />
            <footer>
              <div class="my-5 flex flex-row gap-3">
                <.button_custom phx-disable-with="Saving..." variant="primary">
                  <.icon name="hero-inbox-arrow-down" class="w-4 h-4" /> Simpan
                </.button_custom>
                <.button_custom variant="transparant" navigate={return_path(@return_to, @category)}>
                  <.icon name="hero-arrow-left" class="w-4 h-4" /> Cancel
                </.button_custom>
              </div>
            </footer>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # ============================================================================
  # HANDLE EVENT
  # ============================================================================

  @impl true
  def handle_event("validate", %{"category" => category_params}, socket) do
    changeset = Categories.change_category(socket.assigns.category, category_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"category" => category_params}, socket) do
    save_category(socket, socket.assigns.live_action, category_params)
  end

  # ============================================================================
  # PRIVATE HELPER
  # ============================================================================

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    category = Categories.get_category!(id)

    socket
    |> assign(:page_title, "Edit Category")
    |> assign(:category, category)
    |> assign(:form, to_form(Categories.change_category(category)))
  end

  defp apply_action(socket, :new, _params) do
    category = %Category{}

    socket
    |> assign(:page_title, "Buat Kategori")
    |> assign(:category, category)
    |> assign(:form, to_form(Categories.change_category(category)))
  end

  defp save_category(socket, :edit, category_params) do
    case Categories.update_category(socket.assigns.category, category_params) do
      {:ok, category} ->
        {:noreply,
         socket
         |> put_flash(:info, "Category updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, category))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_category(socket, :new, category_params) do
    case Categories.create_category(category_params) do
      {:ok, category} ->
        {:noreply,
         socket
         |> put_flash(:info, "Category created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, category))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _category), do: ~p"/admin/categories"
  defp return_path("show", category), do: ~p"/admin/categories/#{category}"
end

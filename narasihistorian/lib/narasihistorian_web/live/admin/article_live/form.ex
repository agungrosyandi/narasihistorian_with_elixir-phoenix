defmodule NarasihistorianWeb.Admin.ArticleLive.Form do
  alias Narasihistorian.Articles.Article
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Admin
  alias Narasihistorian.Articles.Article
  alias Narasihistorian.Categories

  # RENDER -----------------------------------------------------------

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex justify-center py-10">
        <div class="w-full rounded-xl border border-zinc-200 shadow-sm">
          
    <!-- HEADER -->

          <div class="border-b border-zinc-200 px-6 py-4">
            <.header>
              <h2 class="text-lg font-semibold">{@page_title}</h2>
            </.header>
          </div>
          
    <!-- FORM ---->

          <div class="relative p-6">
            <.form
              for={@form}
              phx-submit="save"
              phx-change="validate"
              class="space-y-5 flex flex-col gap-3"
            >
              
    <!-- TITLE -->

              <.input
                field={@form[:article_name]}
                label="Title"
                class="input w-full border p-3 shadow-sm"
              />
              
    <!-- DESCRIPTION -->

              <.input
                field={@form[:article_description]}
                type="textarea"
                label="Description"
                phx-debounce="blur"
                class="input w-full p-3 min-h-[100px] border shadow-sm"
              />
              
    <!-- RICH TEXT EDITOR (QUILL) -->

              <div class="form-field">
                <label class="block text-sm font-medium mb-2 text-zinc-400">Content</label>
                <div
                  id={"quill-wrapper-#{@article.id || "new"}"}
                  phx-hook="QuillEditor"
                  phx-update="ignore"
                  data-content={@form[:content].value || ""}
                >
                  <div class="quill-editor" style="height: 300px;"></div>

                  <input
                    type="hidden"
                    name="article[content]"
                    id="article_content"
                    value={@form[:content].value || ""}
                  />
                </div>

                <%= for {msg, _opts} <- @form[:content].errors do %>
                  <p class="mt-2 text-sm text-rose-600 phx-no-feedback:hidden">
                    {msg}
                  </p>
                <% end %>
              </div>
              
    <!-- kategori -->

              <.input
                field={@form[:category_id]}
                type="select"
                label="Kategori"
                prompt="Pilih Kategori"
                options={@category_options}
                class="select w-full border shadow-sm"
              />
              
    <!-- IMAGE UPLOAD -->

              <.input
                field={@form[:image]}
                label="Image"
                class="input w-full border p-3 shadow-sm"
              />
              
    <!-- SUBMIT BUTTON -->

              <div class="flex justify-start pt-4">
                <.button
                  phx-disable-with="Saving...."
                  class="btn btn-neutral"
                >
                  Save Article
                </.button>
              </div>
            </.form>
            
    <!-- BACK TO MAIN MENU -->

            <div class="mt-5">
              <.link navigate={~p"/admin/articles"}>
                <button class="btn btn-link">
                  ⮜ Back to Admin
                </button>
              </.link>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # MOUNT ----------------------------------------------------

  @impl true
  def mount(params, _, socket) do
    socket =
      socket
      |> assign(:category_options, Categories.category_name_and_ids())
      |> apply_action(socket.assigns.live_action, params)

    {:ok, socket}
  end

  # HANDLE EVENT VALIDATE & SAVE --------------------------------------------

  @impl true
  def handle_event("validate", %{"article" => article_params}, socket) do
    changeset = Admin.change_article(socket.assigns.article, article_params)
    socket = assign(socket, :form, to_form(changeset, action: :validate))

    {:noreply, socket}
  end

  def handle_event("save", %{"article" => article_params}, socket) do
    save_article(socket, socket.assigns.live_action, article_params)
  end

  # NEW ----------------------------------------------------

  defp apply_action(socket, :new, _) do
    article = %Article{}

    changeset = Admin.change_article(article)

    socket
    |> assign(:page_title, "New Article")
    |> assign(:form, to_form(changeset))
    |> assign(:article, article)
  end

  # EDIT ----------------------------------------------------

  defp apply_action(socket, :edit, %{"id" => id}) do
    article = Admin.get_article!(id)

    changeset = Admin.change_article(article)

    socket
    |> assign(:page_title, "Edit Article")
    |> assign(:form, to_form(changeset))
    |> assign(:article, article)
  end

  # SAVE NEW ROUTES & EDIT ROUTES  --------------------------------------------

  defp save_article(socket, :new, article_params) do
    case Admin.create_article(article_params) do
      {:ok, _article} ->
        socket =
          socket
          |> put_flash(:info, "Create successful.")
          |> push_navigate(to: ~p"/admin/articles")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign(socket, :form, to_form(changeset))

        {:noreply, socket}
    end
  end

  defp save_article(socket, :edit, article_params) do
    case Admin.update_article(socket.assigns.article, article_params) do
      {:ok, _article} ->
        socket =
          socket
          |> put_flash(:info, "Update successful.")
          |> push_navigate(to: ~p"/admin/articles")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign(socket, :form, to_form(changeset))

        {:noreply, socket}
    end
  end
end

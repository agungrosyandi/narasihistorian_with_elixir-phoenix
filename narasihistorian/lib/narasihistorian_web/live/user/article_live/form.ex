defmodule NarasihistorianWeb.User.ArticleLive.Form do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Articles.Article
  alias Narasihistorian.Admin
  alias Narasihistorian.Categories
  alias Narasihistorian.Uploader

  # ============================================================================
  # MOUNT
  # ============================================================================

  @impl true
  def mount(params, _, socket) do
    # IO.inspect(self(), label: "FORM MOUNT")

    categories_options = Categories.category_name_and_ids()

    socket =
      socket
      |> assign(:category_options, categories_options)
      |> assign(:tag_input, "")
      |> assign(:selected_tags, [])
      |> allow_upload(:image,
        accept: ~w(.jpg .jpeg .png .gif .webp),
        max_entries: 1,
        max_file_size: 5_000_000,
        auto_upload: true
      )
      |> apply_action(socket.assigns.live_action, params)

    {:ok, socket}
  end

  # ============================================================================
  # RENDER
  # ============================================================================

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <%!-- <% IO.inspect(self(), label: "FORM RENDER") %> --%>

      <%!-------------------------%>
      <%!-- HEADER --%>
      <%!-------------------------%>

      <div class="relative p-6 mb-14 flex-1 rounded-xl border border-gray-600 shadow-sm">
        <.main_title_div>
          <.back_link
            navigate={~p"/user/articles"}
            icon="hero-arrow-left"
          />
          <.span_custom variant="main-title">{@page_title}</.span_custom>
        </.main_title_div>

        <%!-------------------------%>
        <%!-- FORM --%>
        <%!-------------------------%>

        <.form
          for={@form}
          phx-submit="save"
          phx-change="validate"
          class="space-y-5"
        >
          <%!-------------------------%>
          <%!-- TITLE --%>
          <%!-------------------------%>

          <.input
            field={@form[:article_name]}
            label="Title"
            class="input w-full border p-3 shadow-sm"
            phx-debounce="blur"
          />

          <%!-------------------------%>
          <%!-- WRITE CONTENT --%>
          <%!-------------------------%>

          <div class="form-field mt-5">
            <label class="block text-xs font-medium mb-1 text-gray-400">Content</label>
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

          <%!-------------------------%>
          <%!-- CATEGORY --%>
          <%!-------------------------%>

          <.input
            field={@form[:category_id]}
            type="select"
            label="Category"
            prompt="Pilih Kategori"
            options={@category_options}
            class="select w-full border shadow-sm"
          />

          <%!-------------------------%>
          <%!-- TAGS INPUT --%>
          <%!-------------------------%>

          <div class="form-field my-5">
            <label class="block text-sm font-medium mb-1 text-gray-400">Tags</label>

            <input
              type="text"
              id="tag-input"
              phx-hook="TagInput"
              value={@tag_input}
              placeholder="Type tag and press Enter"
              class="input w-full border p-3 shadow-sm rounded"
              autocomplete="off"
            />

            <div class="flex flex-wrap gap-2 mt-3">
              <%= for tag <- @selected_tags do %>
                <span class="inline-flex items-center gap-1 px-3 py-1 bg-[#fedf16e0] text-gray-800 font-bold rounded-full text-sm">
                  {tag}
                  <button
                    type="button"
                    phx-click="remove_tag"
                    phx-value-tag={tag}
                    class="hover:text-red-600 ml-1 font-bold cursor-pointer"
                  >
                    ×
                  </button>
                </span>
              <% end %>
            </div>
          </div>

          <%!-------------------------%>
          <%!-- IMAGE UPLOAD --%>
          <%!-------------------------%>

          <div class="form-field my-5">
            <label class="block text-sm font-medium mb-1 text-gray-400">
              Image
            </label>

            <div class="space-y-5">
              <.live_file_input
                upload={@uploads.image}
                class="block text-sm text-zinc-400
                    file:mr-4 file:py-2 file:px-4
                    file:rounded file:border-0
                    file:text-sm file:font-semibold
                    file:bg-zinc-100 file:text-zinc-700
                    hover:file:bg-zinc-200
                    cursor-pointer"
              />

              <p class="text-xs text-zinc-400">
                Accepted: JPG, PNG, GIF, WebP (max 5MB)
              </p>
            </div>

            <%= for entry <- @uploads.image.entries do %>
              <div class="my-5 p-5 border border-gray-500 rounded">
                <div class="flex items-center gap-5 mb-2">
                  <div class="flex-1">
                    <p class="text-sm font-medium text-[#fedf16e0]">
                      {entry.client_name}
                      <span class="text-xs text-[#fedf16e0]">
                        ({format_bytes(entry.client_size)})
                      </span>
                    </p>
                    <div class="h-2 bg-blue-200 rounded overflow-hidden mt-3">
                      <div
                        class="h-full bg-green-400 transition-all"
                        style={"width: #{entry.progress}%"}
                      >
                      </div>
                    </div>
                  </div>
                  <button
                    type="button"
                    phx-click="cancel-upload"
                    phx-value-ref={entry.ref}
                    class="cursor-pointer"
                  >
                    <.icon name="hero-x-circle" class="text-red-600 hover:text-red-800  w-8 h-8" />
                  </button>
                </div>

                <.live_img_preview entry={entry} class="max-w-xs rounded mt-5" />
              </div>
            <% end %>

            <%= for err <- upload_errors(@uploads.image) do %>
              <p class="mt-2 text-sm text-rose-600 bg-rose-50 p-2 rounded">
                {error_to_string(err)}
              </p>
            <% end %>
          </div>

          <%!-------------------------%>
          <%!-- SUBMIT BUTTON --%>
          <%!-------------------------%>

          <footer>
            <div class="my-5 flex flex-row gap-3">
              <.button_custom
                phx-disable-with="Saving...."
                variant="primary"
              >
                <.icon name="hero-inbox-arrow-down" class="w-4 h-4" /> Simpan
              </.button_custom>
            </div>
          </footer>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  # ============================================================================
  # HANDLE EVENT
  # ============================================================================

  # ==================
  # validate & save
  # ===================

  @impl true
  def handle_event("validate", %{"article" => article_params}, socket) do
    changeset = Admin.change_article(socket.assigns.article, article_params)

    socket =
      assign(socket, :form, to_form(changeset, action: :validate))

    {:noreply, socket}
  end

  def handle_event("save", %{"article" => article_params}, socket) do
    save_article(socket, socket.assigns.live_action, article_params)
  end

  # ==================
  # cancel upload
  # ===================

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  # ==================
  # add & remove tag
  # ===================

  @impl true
  def handle_event("add_tag", %{"tag" => tag_name}, socket) do
    tag_name = String.trim(tag_name)

    socket =
      if tag_name != "" and tag_name not in socket.assigns.selected_tags do
        assign(socket, :selected_tags, socket.assigns.selected_tags ++ [tag_name])
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_tag", %{"tag" => tag}, socket) do
    selected_tags = Enum.reject(socket.assigns.selected_tags, &(&1 == tag))

    {:noreply, assign(socket, :selected_tags, selected_tags)}
  end

  # ============================================================================
  # PRIVATE HELPER
  # ============================================================================

  # ====================================
  # apply action
  # ====================================

  defp apply_action(socket, :new, _) do
    article = %Article{}

    changeset = Admin.change_article(article)

    socket
    |> assign(:page_title, "New Article")
    |> assign(:form, to_form(changeset))
    |> assign(:article, article)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    article = Admin.get_article_with_tags!(id)
    changeset = Admin.change_article(article)
    existing_tags = Enum.map(article.tags || [], & &1.name)

    socket
    |> assign(:page_title, "Edit Article")
    |> assign(:form, to_form(changeset))
    |> assign(:article, article)
    |> assign(:selected_tags, existing_tags)
  end

  # ====================================
  # save article
  # ====================================

  defp save_article(%{assigns: %{current_user: current_user}} = socket, :new, article_params) do
    tags = socket.assigns.selected_tags

    case upload_to_r2(socket, article_params) do
      {:ok, article_params_with_image} ->
        case Admin.create_article_with_tags(article_params_with_image, tags, current_user) do
          {:ok, %{article: _article}} ->
            socket =
              socket
              |> put_flash(:info, "Article created & uploaded to cloud successfully!")
              |> push_navigate(to: ~p"/user/articles")

            {:noreply, socket}

          {:error, :article, %Ecto.Changeset{} = changeset, _} ->
            require Logger
            Logger.error("Failed to create article: #{inspect(changeset.errors)}")

            socket =
              socket
              |> assign(:form, to_form(changeset))
              |> put_flash(
                :error,
                "Failed to create article"
              )

            {:noreply, socket}
        end

      {:error, reason} ->
        require Logger
        Logger.error("Failed to upload to R2: #{inspect(reason)}")

        socket =
          socket
          |> put_flash(:error, "Failed to upload image: #{inspect(reason)}")

        {:noreply, socket}
    end
  end

  defp save_article(%{assigns: %{current_user: current_user}} = socket, :edit, article_params) do
    old_image = socket.assigns.article.image
    tags = socket.assigns.selected_tags

    case upload_to_r2(socket, article_params) do
      {:ok, article_params_with_image} ->
        case Admin.update_article_with_tags(
               socket.assigns.article,
               article_params_with_image,
               tags,
               current_user
             ) do
          {:ok, %{article: _article}} ->
            if Map.has_key?(article_params_with_image, "image") && old_image &&
                 old_image != article_params_with_image["image"] do
              delete_old_image(old_image)
            end

            socket =
              socket
              |> put_flash(:info, "Artikel berhasil di updated")
              |> push_navigate(to: ~p"/user/dashboard")

            {:noreply, socket}

          {:error, %Ecto.Changeset{} = changeset} ->
            require Logger
            Logger.error("Failed to update article: #{inspect(changeset.errors)}")

            socket =
              socket
              |> assign(:form, to_form(changeset))
              |> put_flash(
                :error,
                "Failed to update article: #{format_changeset_errors(changeset)}"
              )

            {:noreply, socket}
        end

      {:error, reason} ->
        require Logger
        Logger.error("Failed to upload to R2: #{inspect(reason)}")

        socket =
          socket
          |> put_flash(:error, "Failed to upload image: #{inspect(reason)}")

        {:noreply, socket}
    end
  end

  # ====================================
  # r2 upload
  # ====================================

  defp upload_to_r2(socket, article_params) do
    uploaded_results =
      consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
        require Logger
        Logger.info("Starting upload to R2: #{entry.client_name}")

        filename = Uploader.generate_filename(entry.client_name)
        destination_key = "uploads/#{filename}"

        Logger.info("Destination key: #{destination_key}")
        Logger.info("Content type: #{entry.client_type}")

        case Uploader.upload_file(path, destination_key, entry.client_type) do
          {:ok, public_url} ->
            Logger.info("Successfully uploaded to R2: #{public_url}")
            public_url

          {:error, reason} ->
            Logger.error("R2 upload failed: #{inspect(reason)}")
            {:error, reason}
        end
      end)

    case uploaded_results do
      [public_url | _] when is_binary(public_url) ->
        {:ok, Map.put(article_params, "image", public_url)}

      [{:error, reason} | _] ->
        {:error, reason}

      [] ->
        {:ok, article_params}
    end
  end

  defp delete_old_image(image_url) do
    case Uploader.extract_key(image_url) do
      nil ->
        :ok

      key ->
        Task.start(fn -> Uploader.delete_file(key) end)
        :ok
    end
  end

  # ====================================
  # UI HELPER FUNCTIONS
  # ====================================

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end

  defp format_bytes(bytes) do
    cond do
      bytes >= 1_000_000 -> "#{Float.round(bytes / 1_000_000, 2)} MB"
      bytes >= 1_000 -> "#{Float.round(bytes / 1_000, 2)} KB"
      true -> "#{bytes} B"
    end
  end

  defp error_to_string(:too_large), do: "File terlalu besar (max 5MB)"
  defp error_to_string(:not_accepted), do: "Format file tidak sesuai (JPG, PNG, GIF, WebP only)"
  defp error_to_string(:too_many_files), do: "Terlalu banyak file (max 1)"
  defp error_to_string(err), do: "Upload error: #{inspect(err)}"
end

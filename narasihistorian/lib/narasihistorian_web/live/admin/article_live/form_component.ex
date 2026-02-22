defmodule NarasihistorianWeb.Admin.ArticleLive.FormComponent do
  use NarasihistorianWeb, :live_component

  alias Narasihistorian.Admin
  alias Narasihistorian.Categories
  alias Narasihistorian.Drafts
  alias Narasihistorian.Uploader

  @impl true
  def update(%{article: article} = assigns, socket) do
    category_options = Categories.category_name_and_ids()

    existing_tags =
      case article.tags do
        %Ecto.Association.NotLoaded{} -> []
        nil -> []
        tags -> Enum.map(tags, & &1.name)
      end

    form =
      case assigns[:draft_id] do
        nil ->
          Admin.change_article(article) |> to_form()

        draft_id ->
          case Drafts.get_draft_by_id(draft_id) do
            nil -> Admin.change_article(article) |> to_form()
            draft -> Admin.change_article(article, draft.data) |> to_form()
          end
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:category_options, category_options)
     |> assign(:tag_input, "")
     |> assign(:selected_tags, existing_tags)
     |> assign(:form, form)
     |> assign(:touched_fields, MapSet.new())
     |> allow_upload(:image,
       accept: ~w(.jpg .jpeg .png .gif .webp),
       max_entries: 1,
       max_file_size: 5_000_000
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div
        :if={@draft_id}
        class="mb-4 flex items-center gap-2 text-xs text-amber-400 bg-amber-400/10 border border-amber-400/30 rounded-lg px-3 py-2"
      >
        <.icon name="hero-clock" class="w-3.5 h-3.5 shrink-0" />
        <span>Draft dipulihkan dari penyimpanan</span>
      </div>

      <.form
        for={@form}
        id={"article-form-#{@id}"}
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
        class="space-y-5 text-white"
      >
        <%!-------------------------%>
        <%!-- TITLE & CATEGORY --%>
        <%!-------------------------%>

        <div class="flex flex-col gap-5 md:flex-row">
          <.input
            field={@form[:article_name]}
            label="Title"
            class="input w-full border p-3 shadow-sm"
            phx-debounce="blur"
          />

          <.input
            field={@form[:category_id]}
            type="select"
            label="Category"
            prompt="Pilih Kategori"
            options={@category_options}
            class="select w-full border shadow-sm"
          />
        </div>

        <%!-------------------------%>
        <%!-- CONTENT --%>
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
          </div>

          <input
            type="hidden"
            name="article[content]"
            id="article_content"
            value={@form[:content].value || ""}
          />
        </div>

        <%!-------------------------%>
        <%!-- TAGS --%>
        <%!-------------------------%>

        <div class="form-field my-5">
          <label class="block text-sm font-medium mb-1 text-gray-400">Tags</label>

          <input
            type="text"
            id="tag-input"
            phx-hook="TagInput"
            phx-target={@myself}
            data-target={@myself}
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
                  phx-target={@myself}
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
          <label class="block text-sm font-medium mb-1 text-gray-400">Image</label>

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
            <p class="text-xs text-zinc-400">Accepted: JPG, PNG, GIF, WebP (max 5MB)</p>
          </div>

          <%= for entry <- @uploads.image.entries do %>
            <div class="my-5 p-5 border border-gray-500 rounded">
              <div class="flex items-center gap-5 mb-2">
                <div class="flex-1">
                  <p class="text-sm font-medium text-[#fedf16e0]">
                    {entry.client_name}
                    <span class="text-xs text-[#fedf16e0]">({format_bytes(entry.client_size)})</span>
                  </p>
                  <div class="h-2 bg-blue-200 rounded overflow-hidden mt-3">
                    <div
                      class="h-full bg-green-400 transition-all"
                      style={"width: #{entry.progress}%"}
                    />
                  </div>
                </div>
                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-ref={entry.ref}
                  phx-target={@myself}
                  class="cursor-pointer"
                >
                  <.icon name="hero-x-circle" class="text-red-600 hover:text-red-800 w-8 h-8" />
                </button>
              </div>
              <.live_img_preview entry={entry} class="max-w-xs rounded mt-5" />
            </div>
          <% end %>

          <%= for err <- upload_errors(@uploads.image) do %>
            <p class="mt-2 text-sm text-rose-600 bg-rose-50 p-2 rounded">{error_to_string(err)}</p>
          <% end %>
        </div>

        <button type="submit" id={"submit-#{@id}"} class="hidden" />
      </.form>
    </div>
    """
  end

  # ============================================================================
  # HANDLE EVENT
  # ============================================================================

  @impl true
  def handle_event(
        "validate",
        %{"article" => article_params, "_target" => target} = _params,
        socket
      ) do
    notify_parent(
      {:form_params, socket.assigns.action, socket.assigns.article.id, article_params}
    )

    # Only validate the field that was actually changed, not the whole form.
    # This prevents Quill's hidden input (which may be empty mid-edit) from
    # triggering a "content required" error when the user is typing in the title.
    touched = socket.assigns[:touched_fields] || MapSet.new()

    field =
      case List.last(target) do
        nil -> nil
        "undefined" -> nil
        f -> String.to_atom(f)
      end

    touched = if field, do: MapSet.put(touched, field), else: touched

    changeset =
      socket.assigns.article
      |> Admin.change_article(article_params)
      |> then(fn cs ->
        # Only set :validate action (which shows errors) for touched fields
        if MapSet.size(touched) > 0 do
          Map.put(cs, :action, :validate)
        else
          cs
        end
      end)

    # Filter errors to only show for touched fields
    form = to_form(changeset)

    filtered_errors =
      form.errors
      |> Enum.filter(fn {field, _} -> MapSet.member?(touched, field) end)

    form = %{form | errors: filtered_errors}

    {:noreply,
     socket
     |> assign(:touched_fields, touched)
     |> assign(:form, form)}
  end

  def handle_event("save", %{"article" => article_params}, socket) do
    save_article(socket, socket.assigns.action, article_params)
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  def handle_event("add_tag", %{"tag" => tag_name}, socket) do
    tag_name = String.trim(tag_name)
    selected_tags = socket.assigns.selected_tags

    socket =
      if tag_name != "" and tag_name not in selected_tags do
        assign(socket, :selected_tags, selected_tags ++ [tag_name])
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("remove_tag", %{"tag" => tag}, socket) do
    selected_tags = Enum.reject(socket.assigns.selected_tags, &(&1 == tag))
    {:noreply, assign(socket, :selected_tags, selected_tags)}
  end

  # ============================================================================
  # PRIVATE — SAVE ARTICLE
  # ============================================================================

  defp save_article(socket, :new, article_params) do
    current_user = socket.assigns.current_user
    tags = socket.assigns.selected_tags

    case upload_to_r2(socket, article_params) do
      {:ok, params_with_image} ->
        case Admin.create_article_with_tags(params_with_image, tags, current_user) do
          {:ok, %{article: article}} ->
            if socket.assigns[:draft_id] do
              Drafts.delete_draft_by_id(String.to_integer(socket.assigns.draft_id))
            end

            Drafts.delete_draft(current_user.id, "article", "new", nil)
            notify_parent({:saved, article})

            {:noreply,
             socket
             |> put_flash(:info, "Artikel berhasil dibuat!")
             |> push_navigate(to: socket.assigns.navigate)}

          {:error, :article, %Ecto.Changeset{} = changeset, _} ->
            require Logger
            Logger.error("Failed to create article: #{inspect(changeset.errors)}")

            {:noreply, assign(socket, form: to_form(changeset))}
        end

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Gagal mengunggah gambar: #{inspect(reason)}")}
    end
  end

  defp save_article(socket, :edit, article_params) do
    current_user = socket.assigns.current_user
    old_image = socket.assigns.article.image
    tags = socket.assigns.selected_tags

    case upload_to_r2(socket, article_params) do
      {:ok, params_with_image} ->
        case Admin.update_article_with_tags(
               socket.assigns.article,
               params_with_image,
               tags,
               current_user
             ) do
          {:ok, %{article: article}} ->
            if Map.has_key?(params_with_image, "image") &&
                 old_image && old_image != params_with_image["image"] do
              delete_old_image(old_image)
            end

            if socket.assigns[:draft_id] do
              Drafts.delete_draft_by_id(String.to_integer(socket.assigns.draft_id))
            end

            Drafts.delete_draft(current_user.id, "article", "edit", article.id)
            notify_parent({:saved, article})

            {:noreply,
             socket
             |> put_flash(:info, "Artikel berhasil diperbarui!")
             |> push_navigate(to: socket.assigns.navigate)}

          {:error, :article, %Ecto.Changeset{} = changeset, _} ->
            require Logger
            Logger.error("Failed to update article: #{inspect(changeset.errors)}")

            {:noreply,
             socket
             |> assign(form: to_form(changeset))
             |> put_flash(:error, "Gagal update artikel: #{format_changeset_errors(changeset)}")}
        end

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Gagal mengunggah gambar: #{inspect(reason)}")}
    end
  end

  # ============================================================================
  # PRIVATE — R2 UPLOAD
  # ============================================================================

  defp upload_to_r2(socket, article_params) do
    uploaded_results =
      consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
        require Logger
        Logger.info("Starting upload to R2: #{entry.client_name}")

        filename = Uploader.generate_filename(entry.client_name)
        destination_key = "uploads/#{filename}"

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
      nil -> :ok
      key -> Task.start(fn -> Uploader.delete_file(key) end)
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  # ============================================================================
  # PRIVATE — UI HELPERS
  # ============================================================================

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

  defp error_to_string(:too_large), do: "File is too large (max 5MB)"
  defp error_to_string(:not_accepted), do: "File type not accepted (JPG, PNG, GIF, WebP only)"
  defp error_to_string(:too_many_files), do: "Too many files selected (max 1)"
  defp error_to_string(err), do: "Upload error: #{inspect(err)}"
end

defmodule NarasihistorianWeb.Admin.CategoryLive.FormComponent do
  use NarasihistorianWeb, :live_component

  alias Narasihistorian.Categories
  alias Narasihistorian.Drafts
  alias Narasihistorian.Uploader

  @impl true
  def update(%{category: category} = assigns, socket) do
    form =
      case assigns[:draft_id] do
        nil ->
          Categories.change_category(category) |> to_form()

        draft_id ->
          case Drafts.get_draft_by_id(draft_id) do
            nil -> Categories.change_category(category) |> to_form()
            draft -> Categories.change_category(category, draft.data) |> to_form()
          end
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, form)
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
        id={"category-form-#{@id}"}
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <div class="space-y-4 text-white">
          <.input field={@form[:category_name]} type="text" label="Nama Kategori" />
          <.input field={@form[:description]} type="text" label="Deskripsi Singkat" />

          <div class="form-field">
            <label class="block text-sm font-medium mb-1 text-gray-400">Image</label>
            <div class="space-y-3">
              <.live_file_input
                upload={@uploads.image}
                class="block text-sm text-zinc-400 file:mr-4 file:py-2 file:px-4 file:rounded file:border-0 file:text-sm file:font-semibold file:bg-zinc-100 file:text-zinc-700 hover:file:bg-zinc-200 cursor-pointer"
              />
              <p class="text-xs text-zinc-400">Accepted: JPG, PNG, GIF, WebP (max 5MB)</p>
            </div>

            <%= for entry <- @uploads.image.entries do %>
              <div class="my-5 p-4 border border-gray-500 rounded">
                <div class="flex items-center gap-4 mb-2">
                  <div class="flex-1">
                    <p class="text-sm font-medium text-[#fedf16e0]">
                      {entry.client_name}
                      <span class="text-xs">({format_bytes(entry.client_size)})</span>
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
        </div>

        <button type="submit" id={"submit-#{@id}"} class="hidden" />
      </.form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"category" => params}, socket) do
    # Send latest params to parent Index so it can save as draft on modal close

    notify_parent({:form_params, socket.assigns.action, socket.assigns.category.id, params})

    changeset =
      socket.assigns.category
      |> Categories.change_category(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"category" => params}, socket) do
    save_category(socket, socket.assigns.action, params)
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  defp save_category(socket, :new, params) do
    user = socket.assigns.current_user

    case upload_to_r2(socket, params) do
      {:ok, params_with_image} ->
        case Categories.create_category(params_with_image, user) do
          {:ok, category} ->
            # Delete draft if we came from one

            if socket.assigns[:draft_id] do
              Drafts.delete_draft_by_id(String.to_integer(socket.assigns.draft_id))
            end

            # Also delete any :new draft for this user

            Drafts.delete_draft(user.id, "category", "new", nil)
            notify_parent({:saved, category})

            {:noreply,
             socket
             |> put_flash(:info, "Kategori berhasil dibuat!")
             |> push_navigate(to: socket.assigns.navigate)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, form: to_form(changeset))}
        end

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Gagal mengunggah gambar: #{inspect(reason)}")}
    end
  end

  defp save_category(socket, :edit, params) do
    user = socket.assigns.current_user
    old_image = socket.assigns.category.image_category

    case upload_to_r2(socket, params) do
      {:ok, params_with_image} ->
        case Categories.update_category(socket.assigns.category, params_with_image, user) do
          {:ok, category} ->
            if Map.has_key?(params_with_image, "image_category") &&
                 old_image && old_image != params_with_image["image_category"] do
              delete_old_image(old_image)
            end

            # Delete draft if we came from one

            if socket.assigns[:draft_id] do
              Drafts.delete_draft_by_id(String.to_integer(socket.assigns.draft_id))
            end

            Drafts.delete_draft(user.id, "category", "edit", category.id)
            notify_parent({:saved, category})

            {:noreply,
             socket
             |> put_flash(:info, "Kategori berhasil diperbarui!")
             |> push_navigate(to: socket.assigns.navigate)}

          {:error, :unauthorized} ->
            {:noreply, put_flash(socket, :error, "Tidak memiliki akses")}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, form: to_form(changeset))}
        end

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Gagal mengunggah gambar: #{inspect(reason)}")}
    end
  end

  defp upload_to_r2(socket, params) do
    uploaded_results =
      consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
        filename = Uploader.generate_filename(entry.client_name)
        destination_key = "uploads/#{filename}"

        case Uploader.upload_file(path, destination_key, entry.client_type) do
          {:ok, public_url} -> public_url
          {:error, reason} -> {:error, reason}
        end
      end)

    case uploaded_results do
      [url | _] when is_binary(url) -> {:ok, Map.put(params, "image_category", url)}
      [{:error, reason} | _] -> {:error, reason}
      [] -> {:ok, params}
    end
  end

  defp delete_old_image(image_url) do
    case Uploader.extract_key(image_url) do
      nil -> :ok
      key -> Task.start(fn -> Uploader.delete_file(key) end)
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp format_bytes(bytes) do
    cond do
      bytes >= 1_000_000 -> "#{Float.round(bytes / 1_000_000, 2)} MB"
      bytes >= 1_000 -> "#{Float.round(bytes / 1_000, 2)} KB"
      true -> "#{bytes} B"
    end
  end

  defp error_to_string(:too_large), do: "File is too large (max 5MB)"
  defp error_to_string(:not_accepted), do: "File type not accepted"
  defp error_to_string(:too_many_files), do: "Too many files selected"
  defp error_to_string(err), do: "Upload error: #{inspect(err)}"
end

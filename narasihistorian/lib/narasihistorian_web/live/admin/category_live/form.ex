defmodule NarasihistorianWeb.Admin.CategoryLive.Form do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Categories
  alias Narasihistorian.Categories.Category
  alias Narasihistorian.Uploader

  # ============================================================================
  # MOUNT
  # ============================================================================

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> allow_upload(:image,
       accept: ~w(.jpg .jpeg .png .gif .webp),
       max_entries: 1,
       max_file_size: 5_000_000,
       auto_upload: true
     )
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
        <%!-------------------------%>
        <%!-- IMAGE --%>
        <%!-------------------------%>

        <div class=" w-[100%] lg:block flex-1">
          <img
            class="relative h-full w-full object-cover rounded-lg"
            src="/images/new-bg-1.jpg"
            alt="My Image"
          />
        </div>

        <div class="flex flex-col flex-1 p-8 border border-gray-700 rounded-lg">
          <.main_title_div>
            <.back_link
              navigate={~p"/admin/categories"}
              icon="hero-arrow-left"
            />
            <.span_custom variant="main-title">{@page_title}</.span_custom>
          </.main_title_div>

          <%!-------------------------%>
          <%!-- FORM --%>
          <%!-------------------------%>

          <.form for={@form} id="category-form" phx-change="validate" phx-submit="save">
            <.input field={@form[:category_name]} type="text" label="Nama Kategori" />
            <.input field={@form[:description]} type="text" label="Deskripsi Singkat" />

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

            <footer class="my-5 flex flex-row gap-3">
              <.button_custom phx-disable-with="Saving..." variant="full">
                <.icon name="hero-inbox-arrow-down" class="w-4 h-4" /> Simpan
              </.button_custom>
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

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  # ============================================================================
  # PRIVATE HELPER
  # ============================================================================

  defp apply_action(socket, :edit, %{"id" => id}) do
    category = Categories.get_category!(id)
    changeset = Categories.change_category(category)

    socket
    |> assign(:page_title, "Edit Category")
    |> assign(:category, category)
    |> assign(:form, to_form(changeset))
  end

  defp apply_action(socket, :new, _params) do
    category = %Category{}

    socket
    |> assign(:page_title, "Buat Kategori")
    |> assign(:category, category)
    |> assign(:form, to_form(Categories.change_category(category)))
  end

  # ============================================================================
  # EDIT CATEGORY HELPER
  # ============================================================================

  defp save_category(socket, :edit, category_params) do
    old_image = socket.assigns.category.image_category
    current_user = socket.assigns.current_user

    case upload_to_r2(socket, category_params) do
      {:ok, category_params_with_image} ->
        case Categories.update_category(
               socket.assigns.category,
               category_params_with_image,
               current_user
             ) do
          {:ok, _category} ->
            if Map.has_key?(category_params_with_image, "image_category") && old_image &&
                 old_image != category_params_with_image["image_category"] do
              delete_old_image(old_image)
            end

            socket =
              socket
              |> put_flash(:info, "Category updated & uploaded to cloud successfully!")
              |> push_navigate(to: ~p"/admin/categories")

            {:noreply, socket}

          {:error, :unauthorized} ->
            socket =
              socket
              |> put_flash(:error, "You are not authorized to edit this category")

            {:noreply, socket}

          {:error, %Ecto.Changeset{} = changeset} ->
            require Logger
            Logger.error("Failed to update category: #{inspect(changeset.errors)}")

            socket =
              socket
              |> assign(:form, to_form(changeset))
              |> put_flash(
                :error,
                "Failed to update category: #{format_changeset_errors(changeset)}"
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

  # ============================================================================
  # CREATE CATEGORY HELPER
  # ============================================================================

  defp save_category(socket, :new, category_params) do
    current_user = socket.assigns.current_user

    case upload_to_r2(socket, category_params) do
      {:ok, category_params_with_image} ->
        case Categories.create_category(category_params_with_image, current_user) do
          {:ok, _category} ->
            socket =
              socket
              |> put_flash(:info, "Category created & uploaded to cloud successfully!")
              |> push_navigate(to: ~p"/admin/categories")

            {:noreply, socket}

          {:error, %Ecto.Changeset{} = changeset} ->
            require Logger
            Logger.error("Failed to create category: #{inspect(changeset.errors)}")

            socket =
              socket
              |> assign(:form, to_form(changeset))
              |> put_flash(
                :error,
                "Failed to create category"
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

  # ============================================================================
  # R2 UPLOAD HELPER
  # ============================================================================

  defp upload_to_r2(socket, category_params) do
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
            # Return just the URL, not {:ok, url}
            public_url

          {:error, reason} ->
            Logger.error("R2 upload failed: #{inspect(reason)}")
            {:error, reason}
        end
      end)

    case uploaded_results do
      [public_url | _] when is_binary(public_url) ->
        {:ok, Map.put(category_params, "image_category", public_url)}

      [{:error, reason} | _] ->
        {:error, reason}

      [] ->
        {:ok, category_params}
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

  # ============================================================================
  # UI HELPER FUNCTIONS
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

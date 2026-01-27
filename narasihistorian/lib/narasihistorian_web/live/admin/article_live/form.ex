defmodule NarasihistorianWeb.Admin.ArticleLive.Form do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Articles.Article
  alias Narasihistorian.Admin
  alias Narasihistorian.Categories
  alias Narasihistorian.Uploader

  # MOUNT ----------------------------------------------------

  @impl true
  def mount(params, _, socket) do
    # testing live patch web socket

    # IO.inspect(self(), label: "FORM MOUNT")

    socket =
      socket
      |> assign(:category_options, Categories.category_name_and_ids())
      |> allow_upload(:image,
        accept: ~w(.jpg .jpeg .png .gif .webp),
        max_entries: 1,
        max_file_size: 5_000_000,
        auto_upload: true
      )
      |> apply_action(socket.assigns.live_action, params)

    {:ok, socket}
  end

  # HANDLE EVENT VALIDATE & SAVE --------------------------------------------

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

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
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
    # Upload to R2 first

    case upload_to_r2(socket, article_params) do
      {:ok, article_params_with_image} ->
        case Admin.create_article(article_params_with_image) do
          {:ok, _article} ->
            socket =
              socket
              |> put_flash(:info, "Article created & uploaded to cloud successfully!")
              |> push_navigate(to: ~p"/admin/articles")

            {:noreply, socket}

          {:error, %Ecto.Changeset{} = changeset} ->
            require Logger
            Logger.error("Failed to create article: #{inspect(changeset.errors)}")

            socket =
              socket
              |> assign(:form, to_form(changeset))
              |> put_flash(
                :error,
                "Failed to create article: #{format_changeset_errors(changeset)}"
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

  defp save_article(socket, :edit, article_params) do
    old_image = socket.assigns.article.image

    # Upload to R2 first

    case upload_to_r2(socket, article_params) do
      {:ok, article_params_with_image} ->
        case Admin.update_article(socket.assigns.article, article_params_with_image) do
          {:ok, _article} ->
            # Delete old image from R2 if new image was uploaded

            if Map.has_key?(article_params_with_image, "image") && old_image &&
                 old_image != article_params_with_image["image"] do
              delete_old_image(old_image)
            end

            socket =
              socket
              |> put_flash(:info, "Article updated & uploaded to cloud successfully!")
              |> push_navigate(to: ~p"/admin/articles")

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

  # R2 UPLOAD HELPER FUNCTIONS --------------------------------------------

  defp upload_to_r2(socket, article_params) do
    uploaded_urls =
      consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
        require Logger
        Logger.info("Starting upload to R2: #{entry.client_name}")

        # Generate unique filename

        filename = Uploader.generate_filename(entry.client_name)
        destination_key = "uploads/#{filename}"

        Logger.info("Destination key: #{destination_key}")
        Logger.info("Content type: #{entry.client_type}")

        # Upload to R2

        case Uploader.upload_file(path, destination_key, entry.client_type) do
          {:ok, public_url} ->
            Logger.info("Successfully uploaded to R2: #{public_url}")
            {:ok, public_url}

          {:error, reason} ->
            Logger.error("R2 upload failed: #{inspect(reason)}")
            {:postpone, reason}
        end
      end)

    case uploaded_urls do
      [public_url | _] ->
        {:ok, Map.put(article_params, "image", public_url)}

      [] ->
        {:ok, article_params}

      {:error, reason} ->
        {:error, reason}
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

  # UI HELPER FUNCTIONS --------------------------------------------

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

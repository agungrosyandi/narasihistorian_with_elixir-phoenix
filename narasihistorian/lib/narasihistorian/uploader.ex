defmodule Narasihistorian.Uploader do
  @moduledoc """
  Handles file uploads to Cloudflare R2 storage
  """

  alias ExAws.S3

  @bucket Application.compile_env(:narasihistorian, :r2_bucket)
  @public_url Application.compile_env(:narasihistorian, :r2_public_url)

  @doc """
  Upload a file to R2 and return the public URL

  ## Examples
      iex> upload_file("/tmp/image.jpg", "uploads/abc123.jpg", "image/jpeg")
      {:ok, "https://pub-xxxxx.r2.dev/uploads/abc123.jpg"}
  """

  def upload_file(source_path, destination_key, content_type) do
    require Logger
    Logger.info("Uploader: Reading file from #{source_path}")

    with {:ok, file_binary} <- File.read(source_path),
         _ <-
           Logger.info("Uploader: File read successfully, size: #{byte_size(file_binary)} bytes"),
         {:ok, response} <- do_upload(file_binary, destination_key, content_type),
         _ <- Logger.info("Uploader: Upload successful, response: #{inspect(response)}") do
      public_url = build_public_url(destination_key)
      Logger.info("Uploader: Public URL: #{public_url}")
      {:ok, public_url}
    else
      {:error, reason} = error ->
        Logger.error("Uploader: Upload failed - #{inspect(reason)}")
        error
    end
  end

  @doc """
  Delete a file from R2

  ## Examples
      iex> delete_file("uploads/abc123.jpg")
      {:ok, :deleted}
  """

  def delete_file(key) do
    @bucket
    |> S3.delete_object(key)
    |> ExAws.request()
    |> case do
      {:ok, _} -> {:ok, :deleted}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Extract the key from a full URL

  ## Examples
      iex> extract_key("https://pub-xxxxx.r2.dev/uploads/image.jpg")
      "uploads/image.jpg"
  """

  def extract_key(url) when is_binary(url) do
    String.replace(url, "#{@public_url}/", "")
  end

  def extract_key(_), do: nil

  # Private functions

  defp do_upload(file_binary, key, content_type) do
    require Logger
    Logger.info("Uploader: Uploading to bucket: #{@bucket}, key: #{key}")

    result =
      S3.put_object(@bucket, key, file_binary,
        content_type: content_type,
        acl: :public_read
      )
      |> ExAws.request()

    case result do
      {:ok, response} ->
        Logger.info("Uploader: S3 put_object successful")
        {:ok, response}

      {:error, reason} ->
        Logger.error("Uploader: S3 put_object failed - #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp build_public_url(key) do
    "#{@public_url}/#{key}"
  end

  @doc """
  Generate a unique filename with extension
  """
  def generate_filename(original_filename) do
    ext = Path.extname(original_filename)
    uuid = Ecto.UUID.generate()
    "#{uuid}#{ext}"
  end
end

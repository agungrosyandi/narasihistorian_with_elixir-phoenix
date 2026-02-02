defmodule NarasihistorianWeb.AuthController do
  use NarasihistorianWeb, :controller
  plug Ueberauth

  alias Narasihistorian.Accounts
  alias NarasihistorianWeb.UserAuth

  require Logger

  def request(_conn, _params) do
    # Ueberauth handles the redirect to Google
  end

  def callback(%{assigns: %{ueberauth_failure: fails}} = conn, _params) do
    Logger.error("OAuth authentication failed: #{inspect(fails)}")

    conn
    |> put_flash(:error, "Failed to authenticate with Google. Please try again.")
    |> redirect(to: ~p"/users/log_in")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    # Extract user info from OAuth response

    user_attrs = %{
      email: auth.info.email,
      username: generate_username(auth),
      provider: "google",
      provider_uid: auth.uid,
      provider_token: auth.credentials.token,
      provider_refresh_token: auth.credentials.refresh_token,
      provider_expires_at: expires_at_from_oauth(auth.credentials.expires_at),
      avatar_url: auth.info.image,
      confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }

    case Accounts.find_or_create_oauth_user(user_attrs) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Successfully logged in with Google!")
        |> UserAuth.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = format_changeset_errors(changeset)

        Logger.error("Failed to create/link OAuth user: #{errors}")

        conn
        |> put_flash(:error, "Failed to sign in: #{errors}")
        |> redirect(to: ~p"/users/log_in")
    end
  end

  # Generate username from OAuth data
  defp generate_username(auth) do
    cond do
      # Use name if available
      auth.info.name && auth.info.name != "" ->
        auth.info.name
        |> String.replace(~r/[^a-zA-Z0-9_]/, "")
        |> String.slice(0..24)

      # Use email prefix
      auth.info.email ->
        auth.info.email
        |> String.split("@")
        |> List.first()
        |> String.replace(~r/[^a-zA-Z0-9_]/, "")
        |> String.slice(0..24)

      # Fallback to google + uid
      true ->
        "google_user_#{String.slice(auth.uid, 0..10)}"
    end
  end

  # Helper to convert OAuth expires_at to DateTime

  defp expires_at_from_oauth(nil), do: nil

  defp expires_at_from_oauth(expires_at) when is_integer(expires_at) do
    DateTime.from_unix!(expires_at)
  end

  defp expires_at_from_oauth(%DateTime{} = dt), do: dt

  defp expires_at_from_oauth(_), do: nil

  # Helper to format changeset errors - FIXED VERSION

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, errors} ->
      # Convert errors list to string properly

      error_messages =
        errors
        |> List.flatten()
        |> Enum.join(", ")

      "#{field}: #{error_messages}"
    end)
    |> Enum.join("; ")
  end
end

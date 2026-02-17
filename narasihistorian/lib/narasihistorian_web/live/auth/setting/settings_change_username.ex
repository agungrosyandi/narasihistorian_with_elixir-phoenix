defmodule NarasihistorianWeb.Auth.Setting.SettingsChangeUsername do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Accounts

  import NarasihistorianWeb.CustomComponents, only: [settings_nav: 1]

  # ============================================================================
  # MOUNT
  # ============================================================================

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    username_changeset = Accounts.change_user_username(user)

    socket =
      socket
      |> assign(:current_username, user.username)
      |> assign(:username_form, to_form(username_changeset))

    {:ok, socket}
  end

  # ============================================================================
  # RENDER
  # ============================================================================

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="relative mx-auto w-full h-full space-y-6 rounded-xl shadow-md mb-14">
        <.settings_nav current_page={:change_username} current_user={@current_user} />

        <div class="py-5 border p-5 border-gray-500 rounded-lg">
          <div class="pb-7">
            <h1 class="text-lg font-bold">Manage Username</h1>
            <p class="text-xs mt-2 text-gray-400">Change username settings</p>
          </div>

          <.simple_form
            for={@username_form}
            id="username_form"
            phx-submit="update_username"
            phx-change="validate_username"
          >
            <.input
              field={@username_form[:username]}
              type="text"
              label="Username"
              autocomplete="username"
              required
            />

            <:actions>
              <.button_custom variant="primary" phx-disable-with="Changing...">
                Save Change
              </.button_custom>
            </:actions>
          </.simple_form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # ============================================================================
  # HANDLE EVENT
  # ============================================================================

  def handle_event("validate_username", params, socket) do
    %{"user" => user_params} = params

    username_form =
      socket.assigns.current_user
      |> Accounts.change_user_username(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, username_form: username_form)}
  end

  def handle_event("update_username", params, socket) do
    %{"user" => user_params} = params

    user = socket.assigns.current_user

    case Accounts.update_user_username(user, user_params) do
      {:ok, updated_user} ->
        username_form =
          updated_user
          |> Accounts.change_user_username()
          |> to_form()

        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> put_flash(:info, "Username berhasil diubah")
         |> assign(username_form: username_form, current_username: user_params["username"])}

      {:error, changeset} ->
        {:noreply, assign(socket, username_form: to_form(Map.put(changeset, :action, :insert)))}
    end
  end
end

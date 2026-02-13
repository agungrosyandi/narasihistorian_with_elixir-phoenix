defmodule NarasihistorianWeb.UserLive.Setting.SettingsChangePassword do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Accounts

  import NarasihistorianWeb.CustomComponents, only: [settings_nav: 1]

  # ============================================================================
  # MOUNT
  # ============================================================================

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    password_changeset = Accounts.change_user_password(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  # ============================================================================
  # RENDER
  # ============================================================================

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="relative mx-auto w-full h-full space-y-6 rounded-xl shadow-md mb-14">
        <.settings_nav current_page={:change_password} current_user={@current_user} />

        <div class="py-5 border p-5 border-gray-500 rounded-lg">
          <div class="pb-7">
            <h1 class="text-lg font-bold">Manage Password</h1>
            <p class="text-xs mt-2 text-gray-400">Change password settings</p>
          </div>

          <.simple_form
            for={@password_form}
            id="password_form"
            action={~p"/users/log-in?_action=password-updated"}
            method="post"
            phx-change="validate_password"
            phx-submit="update_password"
            phx-trigger-action={@trigger_submit}
          >
            <input
              name={@password_form[:email].name}
              type="hidden"
              id="hidden_user_email"
              autocomplete="username"
              value={@current_email}
            />

            <.input
              field={@password_form[:current_password]}
              name="current_password"
              type="password"
              label="Current Password"
              id="current_password_for_password"
              value={@current_password}
              autocomplete="current-password"
              required
            />

            <.input
              field={@password_form[:password]}
              type="password"
              label="New Password"
              autocomplete="new-password"
              required
            />

            <.input
              field={@password_form[:password_confirmation]}
              type="password"
              label="Confirm New Password"
              autocomplete="new-password"
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

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end

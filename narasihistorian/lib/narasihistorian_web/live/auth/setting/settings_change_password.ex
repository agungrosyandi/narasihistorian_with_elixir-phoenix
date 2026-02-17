defmodule NarasihistorianWeb.Auth.Setting.SettingsChangePassword do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Accounts
  alias Narasihistorian.Accounts.User

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
      |> assign(:is_oauth_user, User.oauth_user?(user))

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

          <%= if @is_oauth_user do %>
            <div class="flex items-center gap-3 rounded-lg border border-yellow-500/40 bg-yellow-500/10 p-4 text-yellow-400">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="mt-0.5 h-5 w-5 shrink-0"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
              >
                <rect width="18" height="11" x="3" y="11" rx="2" ry="2" />
                <path d="M7 11V7a5 5 0 0 1 10 0v4" />
              </svg>
              <div>
                <p class="text-sm font-semibold">Password settings tidak tersedia</p>
                <p class="mt-1 text-xs text-yellow-400/80">
                  Your account is linked to {User.provider_display_name(@current_user.provider)}.
                  Password is managed through your {User.provider_display_name(@current_user.provider)} account and cannot be changed here.
                </p>
              </div>
            </div>

            <div class="mt-4 cursor-not-allowed opacity-40 select-none" aria-hidden="true">
              <div class="mb-4">
                <label class="block text-sm font-medium mb-1">Current Password</label>
                <input
                  type="password"
                  disabled
                  placeholder="••••••••"
                  class="w-full rounded-md border border-gray-600 bg-gray-800 px-3 py-2 text-sm"
                />
              </div>
              <div class="mb-4">
                <label class="block text-sm font-medium mb-1">New Password</label>
                <input
                  type="password"
                  disabled
                  placeholder="••••••••"
                  class="w-full rounded-md border border-gray-600 bg-gray-800 px-3 py-2 text-sm"
                />
              </div>
              <div class="mb-4">
                <label class="block text-sm font-medium mb-1">Confirm New Password</label>
                <input
                  type="password"
                  disabled
                  placeholder="••••••••"
                  class="w-full rounded-md border border-gray-600 bg-gray-800 px-3 py-2 text-sm"
                />
              </div>
              <button disabled class="rounded-md bg-primary px-4 py-2 text-sm font-medium">
                Save Change
              </button>
            </div>
          <% else %>
            <%!-- NORMAL form for traditional registered users --%>
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
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # ============================================================================
  # HANDLE EVENT
  # ============================================================================

  def handle_event("validate_password", _params, %{assigns: %{is_oauth_user: true}} = socket) do
    {:noreply, socket}
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", _params, %{assigns: %{is_oauth_user: true}} = socket) do
    {:noreply, put_flash(socket, :error, "Aksi tidak diizinkan untuk akun OAuth")}
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

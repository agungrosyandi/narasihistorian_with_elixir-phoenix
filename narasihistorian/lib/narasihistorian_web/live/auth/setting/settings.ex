defmodule NarasihistorianWeb.Auth.Settings do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Accounts
  alias Narasihistorian.Accounts.User

  import NarasihistorianWeb.CustomComponents, only: [settings_nav: 1]

  # ============================================================================
  # MOUNT
  # ============================================================================

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email berhasil dirubah")

        :error ->
          put_flash(socket, :error, "Pergantian email gagal")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    oauth_user = User.oauth_user?(user)

    socket =
      socket
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:is_oauth_user, oauth_user)

    {:ok, socket}
  end

  # ============================================================================
  # RENDER
  # ============================================================================

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="relative mx-auto w-full h-full space-y-6 rounded-xl shadow-md mb-14">
        <.settings_nav current_page={:settings} current_user={@current_user} />

        <div class="py-5 border p-5 border-gray-500 rounded-lg">
          <div class="pb-7">
            <h1 class="text-lg font-bold">Manage Email</h1>
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
                <p class="text-sm font-semibold">Email settings tidak tersedia</p>
                <p class="mt-1 text-xs text-yellow-400/80">
                  Your account is linked to Google. Email and password are managed through your Google account and cannot be changed here.
                </p>
              </div>
            </div>

            <div class="mt-4 cursor-not-allowed opacity-40 select-none" aria-hidden="true">
              <div class="mb-4">
                <label class="block text-sm font-medium mb-1">Email</label>
                <input
                  type="email"
                  disabled
                  value={@current_email}
                  class="w-full rounded-md border border-gray-600 bg-gray-800 px-3 py-2 text-sm"
                />
              </div>
              <div class="mb-4">
                <label class="block text-sm font-medium mb-1">Confirm Password</label>
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
            <%!-- NORMAL form for regular registered users --%>
            <.simple_form
              for={@email_form}
              id="email_form"
              phx-submit="update_email"
              phx-change="validate_email"
            >
              <.input
                field={@email_form[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                required
              />
              <.input
                field={@email_form[:current_password]}
                name="current_password"
                id="current_password_for_email"
                type="password"
                label="Confirm Password"
                value={@email_form_current_password}
                autocomplete="current-password"
                required
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

  def handle_event("validate_email", _params, %{assigns: %{is_oauth_user: true}} = socket) do
    {:noreply, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", _params, %{assigns: %{is_oauth_user: true}} = socket) do
    {:noreply, put_flash(socket, :error, "Aksi tidak diizinkan untuk akun Google")}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        info =
          "Link konfirmasi perubahan email telah dikirimkan ke emailmu, klik link konfirmasi di email mu untuk menyeleseikan proses perubahan email"

        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end
end

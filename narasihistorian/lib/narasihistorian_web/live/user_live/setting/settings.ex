defmodule NarasihistorianWeb.UserLive.Settings do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Accounts

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

    socket =
      socket
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))

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
        </div>
      </div>
    </Layouts.app>
    """
  end

  # ============================================================================
  # HANDLE EVENT
  # ============================================================================

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
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

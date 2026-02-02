defmodule NarasihistorianWeb.UserLive.Settings do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Accounts

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
    username_changeset = Accounts.change_user_username(user)
    password_changeset = Accounts.change_user_password(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:current_username, user.username)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:username_form, to_form(username_changeset))
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
        <.header class="text-center">
          Account Settings
          <:subtitle>Manage your account email address and password settings</:subtitle>
        </.header>

        <div class="py-5 border p-5 border-gray-500 rounded-lg">
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
              label="Current password"
              value={@email_form_current_password}
              autocomplete="current-password"
              required
            />
            <:actions>
              <.button phx-disable-with="Changing...">Change Email</.button>
            </:actions>
          </.simple_form>
        </div>

        <%!-- username --%>

        <div class="py-5 border p-5 border-gray-500 rounded-lg">
          <.simple_form
            for={@username_form}
            id="username_form"
            phx-submit="update_username"
            phx-change="validate_username"
          >
            <%!-- current username --%>

            <.input
              field={@username_form[:username]}
              type="text"
              label="Username"
              autocomplete="username"
              required
            />

            <:actions>
              <.button phx-disable-with="Changing...">Change Username</.button>
            </:actions>
          </.simple_form>
        </div>

        <div class="py-5 border p-5 border-gray-500 rounded-lg">
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

            <%!-- new password --%>

            <.input
              field={@password_form[:current_password]}
              name="current_password"
              type="password"
              label="Old password"
              id="current_password_for_password"
              value={@current_password}
              autocomplete="current-password"
              required
            />

            <%!-- new password --%>

            <.input
              field={@password_form[:password]}
              type="password"
              label="New password"
              autocomplete="new-password"
              required
            />

            <%!-- password confirm --%>

            <.input
              field={@password_form[:password_confirmation]}
              type="password"
              label="Confirm new password"
              autocomplete="new-password"
            />

            <:actions>
              <.button phx-disable-with="Changing...">Change Password</.button>
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

  # EMAIL

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

  # USERNAME

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

  # PASSWORD

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

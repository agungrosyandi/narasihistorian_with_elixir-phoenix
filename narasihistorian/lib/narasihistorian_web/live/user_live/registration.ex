defmodule NarasihistorianWeb.UserLive.Registration do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Accounts
  alias Narasihistorian.Accounts.User

  # ============================================================================
  # MOUNT
  # ============================================================================

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  # ============================================================================
  # RENDER
  # ============================================================================

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="relative flex w-full flex-col gap-3 mb-10 lg:min-h-[70vh] lg:flex-row shadow-lg">
        <div class="hidden w-[100%] lg:block">
          <img
            class="relative h-full w-full object-cover"
            src="/images/40.jpg"
            alt="My Image"
          />
        </div>

        <div class="mx-auto w-full h-full space-y-6 mb-10 rounded-xl p-3 lg:p-5">
          <.header class="text-center">
            <div class="flex flex-row items-center py-5">
              <div class="h-[0.1rem] w-full bg-gray-600"></div>
              <p class="px-5 text-2xl">REGISTER</p>
              <div class="h-[0.1rem] w-full bg-gray-600"></div>
            </div>

            <h3 class="flex flex-col items-center justify-center w-full text-center text-sm md:flex-row">
              Already registered ?
              <.link
                navigate={~p"/users/log-in"}
                class="font-semibold text-[#fedf16e0] text-brand hover:underline"
              >
                &nbsp  Log in &nbsp
              </.link>
              to your account now.
            </h3>
          </.header>

          <.simple_form
            for={@form}
            id="registration_form"
            phx-submit="save"
            phx-change="validate"
            phx-trigger-action={@trigger_submit}
            action={~p"/users/log-in?_action=registered"}
            method="post"
          >
            <.error :if={@check_errors}>
              Oops, something went wrong! Please check the errors below.
            </.error>

            <.input
              field={@form[:email]}
              type="email"
              label="Email"
              autocomplete="username"
              required
            />

            <.input
              field={@form[:username]}
              label="Username"
              required
            />

            <.input
              type="select"
              field={@form[:role]}
              prompt="Role"
              options={[Admin: "admin", User: "user"]}
            />

            <.input
              field={@form[:password]}
              type="password"
              label="Password"
              autocomplete="new-password"
              required
            />

            <:actions>
              <.button_custom phx-disable-with="Creating account..." variant="full">
                Create an account
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

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  # ============================================================================
  # PRIVATE HELPER
  # ============================================================================

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end

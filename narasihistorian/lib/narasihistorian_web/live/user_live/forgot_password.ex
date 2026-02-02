defmodule NarasihistorianWeb.UserLive.ForgotPassword do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Accounts

  # ============================================================================
  # MOUNT
  # ============================================================================

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  # ============================================================================
  # RENDER
  # ============================================================================

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
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
              <div class="flex flex-row px-5 text-2xl">
                <p class="">Forgot</p>
                <p class="px-2">your</p>
                <p class="">Password</p>
              </div>
              <div class="h-[0.1rem] w-full bg-gray-600"></div>
            </div>

            <h3 class="flex items-center justify-center w-full text-center text-sm">
              We'll send a password reset link to your inbox
            </h3>
          </.header>

          <.simple_form for={@form} id="reset_password_form" phx-submit="send_email">
            <.input
              field={@form[:email]}
              type="email"
              placeholder="Masukan Email Valid ...."
              autocomplete="username"
              required
            />
            <:actions>
              <.button_custom phx-disable-with="Sending..." variant="full">
                Send password reset instructions
              </.button_custom>
            </:actions>
          </.simple_form>
          <p class="text-center text-sm mt-4">
            <.link class="hover:text-[#fedf16e0]" navigate={~p"/users/register"}>Register</.link>
            &nbsp  | &nbsp
            <.link class="hover:text-[#fedf16e0]" navigate={~p"/users/log-in"}>Log in</.link>
          </p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # ============================================================================
  # HANDLE EVENT
  # ============================================================================

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset-password/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end

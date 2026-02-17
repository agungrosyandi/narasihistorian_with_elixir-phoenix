defmodule NarasihistorianWeb.Auth.Login do
  use NarasihistorianWeb, :live_view

  # ============================================================================
  # MOUNT
  # ============================================================================

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end

  # ============================================================================
  # RENDER
  # ============================================================================

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="relative flex w-full flex-col gap-3 mb-10 lg:min-h-[70vh] lg:flex-row shadow-lg ">
        <%!-------------------------%>
        <%!-- IMAGE --%>
        <%!-------------------------%>

        <div class="hidden w-[100%] lg:block">
          <img
            class="relative h-full w-full object-cover"
            src="/images/40.jpg"
            alt="My Image"
          />
        </div>

        <div class="mx-auto w-full h-full space-y-6 mb-10 rounded-xl p-3 lg:p-5">
          <.header>
            <div class="flex flex-row items-center py-5">
              <div class="h-[0.1rem] w-full bg-gray-600"></div>
              <p class="px-5 text-2xl">LOGIN</p>
              <div class="h-[0.1rem] w-full bg-gray-600"></div>
            </div>

            <h3 class="flex flex-col items-center justify-center w-full text-center text-sm md:flex-row">
              Don't have an account ?
              <.link
                navigate={~p"/users/register"}
                class="font-semibold text-[#fedf16e0] text-brand hover:underline"
              >
                &nbsp Sign up &nbsp
              </.link>
              for an account now.
            </h3>
          </.header>

          <.simple_form for={@form} id="login_form" action={~p"/users/log-in"} phx-update="ignore">
            <.input field={@form[:email]} type="email" label="Email" autocomplete="username" required />
            <.input
              field={@form[:password]}
              type="password"
              label="Password"
              autocomplete="current-password"
              required
            />

            <:actions>
              <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
              <.link navigate={~p"/users/reset-password"} class="text-xs hover:text-[#fedf16e0]">
                Forgot your password ?
              </.link>
            </:actions>
            <:actions>
              <.button_custom variant="full">
                Login
              </.button_custom>
            </:actions>
          </.simple_form>

          <div class="flex flex-row items-center">
            <div class="h-[0.1rem] w-full bg-gray-600"></div>
            <p class="px-5 text-base">or</p>
            <div class="h-[0.1rem] w-full bg-gray-600"></div>
          </div>

          <.link
            href={~p"/auth/google"}
            class="text-white flex flex-row items-center justify-center rounded-lg text-sm border border-white/30 p-2  hover:bg-white/10 hover:border-[#fedf16e0] font-normal transition-all duration-200"
          >
            <svg class="w-4 h-4 mr-3" viewBox="0 0 24 24">
              <path
                fill="#4285F4"
                d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
              />
              <path
                fill="#34A853"
                d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
              />
              <path
                fill="#FBBC05"
                d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
              />
              <path
                fill="#EA4335"
                d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
              />
            </svg>
            Sign in with Google
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end
end

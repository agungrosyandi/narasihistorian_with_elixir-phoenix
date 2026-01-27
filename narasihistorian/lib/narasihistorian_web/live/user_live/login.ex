defmodule NarasihistorianWeb.UserLive.Login do
  use NarasihistorianWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="relative flex w-full flex-col gap-3 lg:min-h-[70vh] lg:flex-row shadow-lg ">
        
    <!-- image ----------------->

        <div class="w-[100%]">
          <img
            class="relative h-full w-full object-cover"
            src="/images/40.jpg"
            alt="My Image"
          />
        </div>

        <div class="mx-auto w-full h-full space-y-6 rounded-xl p-8">
          <.header class="">
            <h3 class="mb-2 text-lg font-bold">
              Log in to account
            </h3>

            <:subtitle>
              Don't have an account?
              <.link navigate={~p"/users/register"} class="font-semibold text-brand hover:underline">
                Sign up
              </.link>
              for an account now.
            </:subtitle>
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
              <.link href={~p"/users/reset-password"} class="text-sm font-semibold">
                Forgot your password?
              </.link>
            </:actions>
            <:actions>
              <.button class="btn w-full">
                Login
              </.button>
            </:actions>
          </.simple_form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end

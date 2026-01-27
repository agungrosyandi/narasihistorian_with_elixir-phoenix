defmodule NarasihistorianWeb.Router do
  use NarasihistorianWeb, :router

  import NarasihistorianWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {NarasihistorianWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # controller - https

  scope "/", NarasihistorianWeb do
    pipe_through :browser

    get "/", ArticleController, :index
    get "/articles", ArticleController, :index
    get "/articles/:id", ArticleController, :show

    post "/articles/:id/comments", CommentController, :create
    delete "/articles/:id/comments/:comment_id", CommentController, :delete
  end

  scope "/", NarasihistorianWeb.Admin do
    pipe_through [:browser, :require_authenticated_user]

    live_session :admin_area,
      on_mount: [{NarasihistorianWeb.UserAuth, :ensure_authenticated}] do
      # Articles - accessible to all authenticated users

      live "/admin/articles", ArticleLive.Index, :index
      live "/admin/articles/new", ArticleLive.Form, :new
      live "/admin/articles/:id/edit", ArticleLive.Form, :edit

      # Categories - will check admin role in mount/3

      live "/admin/categories", CategoryLive.Index, :index
      live "/admin/categories/new", CategoryLive.Form, :new
      live "/admin/categories/:id", CategoryLive.Show, :show
      live "/admin/categories/:id/edit", CategoryLive.Form, :edit

      live "/admin/dashboard", DashboardLive.Index, :index
    end
  end

  # Other scopes may use custom stacks.

  scope "/api", NarasihistorianWeb.Api do
    pipe_through :api

    get "/articles", ArticleController, :index
    get "/articles/:id", ArticleController, :show
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:narasihistorian, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:browser, :require_admin]

      live_dashboard "/dashboard", metrics: NarasihistorianWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", NarasihistorianWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{NarasihistorianWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/reset-password", UserLive.ForgotPassword, :new
      live "/users/reset-password/:token", UserLive.ResetPassword, :edit
    end

    post "/users/log-in", UserSessionController, :create
  end

  scope "/", NarasihistorianWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{NarasihistorianWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end
  end

  scope "/", NarasihistorianWeb do
    pipe_through [:browser]

    delete "/users/log-out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{NarasihistorianWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserLive.Confirmation, :edit
      live "/users/confirm", UserLive.ConfirmationInstructions, :new
    end
  end
end

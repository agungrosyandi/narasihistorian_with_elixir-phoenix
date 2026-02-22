defmodule NarasihistorianWeb.Router do
  use NarasihistorianWeb, :router

  import NarasihistorianWeb.UserAuth

  # ============================================================================
  # PLUG
  # ============================================================================

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

  # ============================================================================
  # CONTROLLER - HTTPS PUBLIC ARTICLE
  # ============================================================================

  scope "/", NarasihistorianWeb do
    pipe_through :browser

    # Article

    get "/", ArticleController, :index
    get "/articles", ArticleController, :index
    get "/articles/more", ArticleController, :more
    get "/articles/tags/:tag_slug", ArticleController, :by_tag
    get "/articles/tags/:tag_slug/more", ArticleController, :by_tag_more
    get "/articles/:id", ArticleController, :show
    get "/articles/:id/comments/more", ArticleController, :comments_more

    post "/articles/:id/comments", CommentController, :create
    delete "/articles/:id/comments/:comment_id", CommentController, :delete

    # Category

    get "/categories", CategoryController, :index
    get "/categories/:id", CategoryController, :show
    get "/categories/:id/more", CategoryController, :more
  end

  # ============================================================================
  # OAUTH AND USER
  # ============================================================================

  scope "/auth", NarasihistorianWeb do
    pipe_through :browser

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  # ============================================================================
  # LIVEVIEW
  # ============================================================================

  scope "/user", NarasihistorianWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :user_area,
      on_mount: [{NarasihistorianWeb.UserAuth, :ensure_authenticated}] do
      live "/dashboard", User.DashboardLive.Index, :index
      live "/articles", User.ArticleLive.Index, :index
      live "/articles/new", User.ArticleLive.Form, :new
      live "/articles/:id/edit", User.ArticleLive.Form, :edit
    end
  end

  scope "/admin", NarasihistorianWeb.Admin, as: :admin do
    pipe_through [:browser, :require_authenticated_user, :require_admin]

    live_session :admin_area,
      on_mount: [{NarasihistorianWeb.UserAuth, :ensure_authenticated}] do
      live "/dashboard", DashboardLive.Index, :index
      live "/dashboard/drafts", DashboardLive.Drafts, :index
      live "/dashboard/profile", DashboardLive.Profile, :index

      live "/articles", ArticleLive.Index, :index
      # live "/articles/new", ArticleLive.Form, :new
      # live "/articles/:id/edit", ArticleLive.Form, :edit
      live "/articles/new", ArticleLive.Index, :new
      live "/articles/:id/edit", ArticleLive.Index, :edit

      live "/categories", CategoryLive.Index, :index
      live "/categories/new", CategoryLive.Index, :new
      live "/categories/:id/edit", CategoryLive.Index, :edit
      live "/categories/:id", CategoryLive.Show, :show
    end
  end

  # ============================================================================
  # API
  # ============================================================================

  scope "/api", NarasihistorianWeb.Api do
    pipe_through :api

    # get "/articles", ArticleController, :index
    # get "/articles/:id", ArticleController, :show
  end

  # ============================================================================
  # ENABLE LIVEDASHBOARD AND SWOOSH MAILBOX PREVIEW IN DEVELOPMENT
  # ============================================================================

  if Application.compile_env(:narasihistorian, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      # pipe_through [:browser, :require_admin]
      pipe_through :browser

      live_dashboard "/dashboard", metrics: NarasihistorianWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  # ============================================================================
  # AUTHENTICATION ROUTES
  # ============================================================================

  scope "/", NarasihistorianWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{NarasihistorianWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", Auth.Registration, :new
      live "/users/log-in", Auth.Login, :new
      live "/users/reset-password", Auth.ForgotPassword, :new
      live "/users/reset-password/:token", Auth.ResetPassword, :edit
    end

    post "/users/log-in", UserSessionController, :create
  end

  scope "/", NarasihistorianWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{NarasihistorianWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", Auth.Settings, :edit
      live "/users/settings/change-username", Auth.Setting.SettingsChangeUsername, :edit
      live "/users/settings/change-password", Auth.Setting.SettingsChangePassword, :edit
      live "/users/settings/confirm-email/:token", Auth.Settings, :confirm_email
    end
  end

  scope "/", NarasihistorianWeb do
    pipe_through [:browser]

    delete "/users/log-out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{NarasihistorianWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", Auth.Confirmation, :edit
      live "/users/confirm", Auth.ConfirmationInstructions, :new
    end
  end
end

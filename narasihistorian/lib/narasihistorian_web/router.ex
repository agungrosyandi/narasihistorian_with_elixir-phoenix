defmodule NarasihistorianWeb.Router do
  use NarasihistorianWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {NarasihistorianWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", NarasihistorianWeb do
    pipe_through :browser

    get "/", ArticleController, :index
    get "/articles", ArticleController, :index
    get "/articles/:id", ArticleController, :show
  end

  # Admin routes - LiveView

  scope "/admin", NarasihistorianWeb.Admin do
    pipe_through [:browser]

    live "/articles", ArticleLive.Index, :index
    live "/articles/new", ArticleLive.Form, :new
    live "/articles/:id/edit", ArticleLive.Form, :edit

    live "/categories", CategoryLive.Index, :index
    live "/categories/new", CategoryLive.Form, :new
    live "/categories/:id", CategoryLive.Show, :show
    live "/categories/:id/edit", CategoryLive.Form, :edit
  end

  # Other scopes may use custom stacks.
  # scope "/api", NarasihistorianWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:narasihistorian, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: NarasihistorianWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

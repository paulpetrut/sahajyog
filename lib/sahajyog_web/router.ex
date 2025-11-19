defmodule SahajyogWeb.Router do
  use SahajyogWeb, :router

  import SahajyogWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SahajyogWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
    plug SahajyogWeb.Plugs.Locale
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SahajyogWeb do
    pipe_through :browser

    live_session :default,
      on_mount: [
        {SahajyogWeb.UserAuth, :mount_current_scope},
        {SahajyogWeb.LocaleLive, :default}
      ] do
      live "/", WelcomeLive
      live "/steps", StepsLive
      live "/talks", TalksLive
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", SahajyogWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:sahajyog, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SahajyogWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", SahajyogWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [
        {SahajyogWeb.UserAuth, :require_authenticated},
        {SahajyogWeb.LocaleLive, :default}
      ] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
      live "/admin/videos", Admin.VideosLive
      live "/admin/resources", Admin.ResourcesLive, :index
      live "/admin/resources/new", Admin.ResourcesLive, :new
      live "/admin/resources/:id/edit", Admin.ResourcesLive, :edit
      live "/resources", ResourcesLive
    end

    get "/resources/:id/download", ResourceController, :download
    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", SahajyogWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [
        {SahajyogWeb.UserAuth, :mount_current_scope},
        {SahajyogWeb.LocaleLive, :default}
      ] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end

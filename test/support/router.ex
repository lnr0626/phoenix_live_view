defmodule Phoenix.LiveViewTest.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]

    plug Plug.Session,
      store: :cookie,
      key: "_live_view_key",
      signing_salt: "/VEDsdfsffMnp5"

    plug :fetch_session
    plug Phoenix.LiveView.Flash
  end

  pipeline :bad_layout do
    plug :put_layout, {UnknownView, :unknown_template}
  end

  scope "/", Phoenix.LiveViewTest do
    pipe_through [:browser]

    # controller test
    get "/controller/:type", Controller, :incoming
    get "/widget", Controller, :widget

    # router test
    live "/router/thermo_defaults/:id", DashboardLive
    live "/router/thermo_session/:id", DashboardLive
    live "/router/thermo_container/:id", DashboardLive, container: {:span, style: "flex-grow"}
    live "/router/thermo_session/custom/:id", DashboardLive, as: :custom_live
    live "/router/foobarbaz", FooBarLive, :index
    live "/router/foobarbaz/index", FooBarLive.Index, :index
    live "/router/foobarbaz/show", FooBarLive.Index, :show
    live "/router/foobarbaz/nested/index", FooBarLive.Nested.Index, :index
    live "/router/foobarbaz/nested/show", FooBarLive.Nested.Index, :show
    live "/router/foobarbaz/custom", FooBarLive, :index, as: :custom_foo_bar

    live "/thermo", ThermostatLive
    live "/thermo/:id", ThermostatLive
    live "/thermo-container", ThermostatLive, container: {:span, style: "thermo-flex<script>"}
    live "/", ThermostatLive, as: :live_root
    live "/clock", ClockLive
    live "/redir", RedirLive

    live "/same-child", SameChildLive
    live "/root", RootLive
    live "/opts", OptsLive
    live "/time-zones", AppendLive
    live "/shuffle", ShuffleLive
    live "/components", WithComponentLive

    # integration layout
    scope "/" do
      pipe_through [:bad_layout]

      # The layout option needs to have higher precedence than bad layout
      live "/bad_layout", LayoutLive
      live "/layout", LayoutLive, layout: {Phoenix.LiveViewTest.LayoutView, :app}
    end

    # integration params
    live "/counter/:id", ParamCounterLive
    live "/action", ActionLive
    live "/action/index", ActionLive, :index
    live "/action/:id/edit", ActionLive, :edit

    # integration flash
    live "/flash-root", FlashLive
    live "/flash-child", FlashChildLive
  end
end

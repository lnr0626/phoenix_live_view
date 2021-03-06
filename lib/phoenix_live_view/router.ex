defmodule Phoenix.LiveView.Router do
  @moduledoc """
  Provides LiveView routing for Phoenix routers.
  """

  @doc """
  Defines a LiveView route.

  A LiveView can be routed to by using the `live` macro with a path and
  the name of the LiveView:

      live "/thermostat", ThermostatLive

  By default, you can generate a route to this LiveView by using the `live_path` helper:

      live_path(@socket, ThermostatLive)

  ## Actions and live navigation

  It is common for a LiveView to have multiple states and multiple URLs.
  For example, you can have a single LiveView that lists all articles on
  your web app. For each article there is an "Edit" button which, when
  pressed, opens up a modal on the same page to edit the article. It is a
  best practice to use live navigation in those cases, so when you click
  edit, the URL changes to "/articles/1/edit", even though you are still
  within the same LiveView. Similarly, you may also want to show a "New"
  button, which opens up the modal to create new entries, and you want
  that to reflect in the URL as "/articles/new".

  In order to make it easier to recognize the current "action" your
  LiveView is on, you can pass the action option when defining LiveViews
  too:

      live "/articles", ArticleLive.Index, :index
      live "/articles/new", ArticleLive.Index, :new
      live "/articles/1/edit", ArticleLive.Index, :edit

  When an action is given, the generated route helpers are named after
  the LiveView itself (the same as in a controller). For the example
  above, we will have:

      article_index_path(@socket, :index)
      article_index_path(@socket, :new)
      article_index_path(@socket, :edit, 123)

  The current action will always be available inside the LiveView as
  the `@live_view_action` assign. `@live_view_action` will be `nil`
  if no action is given on the route definition.

  ## Layout

  When a layout isn't explicitly set, a default layout is inferred similar to
  controllers. For example, the layout for the router `MyAppWeb.Router`
  would be inferred as `MyAppWeb.LayoutView` and would use the `:app` template.

  ## Options

    * `:session` - a map of strings keys and values to be merged into the session.

    * `:layout` - the optional tuple for specifying a layout to render the
      LiveView. Defaults to `{LayoutView, :app}` where LayoutView is relative to
      your application's namespace.

    * `:container` - the optional tuple for the HTML tag and DOM attributes to
      be used for the LiveView container. For example: `{:li, style: "color: blue;"}`.
      See `Phoenix.LiveView.live_render/3` for more information on examples.

    * `:as` - optionally configures the named helper. Defaults to `:live` when
      using a LiveView without actions or default to the LiveView name when using
      actions.

  ## Examples

      defmodule MyApp.Router
        use Phoenix.Router
        import Phoenix.LiveView.Router

        scope "/", MyApp do
          pipe_through [:browser]

          live "/thermostat", ThermostatLive
          live "/clock", ClockLive
          live "/dashboard", DashboardLive, layout: {MyApp.AlternativeView, "app.html"}
        end
      end

      iex> MyApp.Router.Helpers.live_path(MyApp.Endpoint, MyApp.ThermostatLive)
      "/thermostat"

  """
  defmacro live(path, live_view, action \\ nil, opts \\ []) do
    quote bind_quoted: binding() do
      {action, router_options} =
        Phoenix.LiveView.Router.__live__(__MODULE__, live_view, action, opts)

      Phoenix.Router.get(path, Phoenix.LiveView.Plug, action, router_options)
    end
  end

  @doc false
  def __live__(router, live_view, action, opts) when is_list(action) and is_list(opts) do
    __live__(router, live_view, nil, Keyword.merge(action, opts))
  end

  def __live__(router, live_view, action, opts) when is_atom(action) and is_list(opts) do
    live_view = Phoenix.Router.scoped_alias(router, live_view)

    opts =
      opts
      |> Keyword.put(:router, router)
      |> Keyword.put(:action, action)
      |> Keyword.put(:inferred_layout, inferred_layout(router))

    {as_helper, as_action} = inferred_as(live_view, action)

    {as_action,
     as: opts[:as] || as_helper,
     private: %{phoenix_live_view: {live_view, opts}},
     alias: false,
     metadata: %{phoenix_live_view: {live_view, action}}}
  end

  defp inferred_as(live_view, nil), do: {:live, live_view}

  defp inferred_as(live_view, action) do
    live_view
    |> Module.split()
    |> Enum.drop_while(&(not String.ends_with?(&1, "Live")))
    |> Enum.map(& &1 |> String.replace_suffix("Live", "") |> Macro.underscore)
    |> Enum.join("_")
    |> case do
      "" ->
        raise ArgumentError,
              "could not infer :as option because a live action was given and the LiveView " <>
              "does not have a \"Live\" suffix. Please pass :as explicitly or make sure your " <>
              "LiveView is named like \"FooLive\" or \"FooLive.Index\""

      as ->
        {String.to_atom(as), action}
    end
  end

  defp inferred_layout(router) do
    layout_view =
      router
      |> Atom.to_string()
      |> String.split(".")
      |> Enum.drop(-1)
      |> Kernel.++(["LayoutView"])
      |> Module.concat()

    {layout_view, :app}
  end
end

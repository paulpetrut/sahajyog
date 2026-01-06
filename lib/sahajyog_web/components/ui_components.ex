defmodule SahajyogWeb.UIComponents do
  @moduledoc """
  Shared UI components for consistent design across the application.
  """
  use Phoenix.Component
  use Gettext, backend: SahajyogWeb.Gettext

  import SahajyogWeb.CoreComponents, only: [icon: 1]

  alias Phoenix.LiveView.JS

  @doc """
  Renders a page container with consistent gradient background.

  ## Examples

      <.page_container>
        <h1>Content</h1>
      </.page_container>
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def page_container(assigns) do
    ~H"""
    <div
      class={[
        "min-h-screen bg-gradient-to-br from-base-300 via-base-200 to-base-300 noise-overlay",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a card component with consistent styling.

  ## Examples

      <.card>
        <p>Card content</p>
      </.card>

      <.card size="lg" hover>
        <p>Large hoverable card</p>
      </.card>
  """
  attr :class, :any, default: nil
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :hover, :boolean, default: false
  attr :rest, :global
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div
      class={[
        "bg-gradient-to-br from-base-200 to-base-300 rounded-xl border border-base-content/10",
        card_padding(@size),
        @hover &&
          "hover:border-primary/50 transition-all duration-300 hover:shadow-2xl hover:shadow-primary/10",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp card_padding("sm"), do: "p-3 sm:p-4"
  defp card_padding("md"), do: "p-3 sm:p-4 md:p-6"
  defp card_padding("lg"), do: "p-3 sm:p-4 md:p-6 lg:p-8"

  @doc """
  Renders an empty state with icon, title, and description.

  ## Examples

      <.empty_state
        icon="hero-document-text"
        title="No topics yet"
        description="Be the first to create a topic"
      />
  """
  attr :icon, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :class, :string, default: nil
  attr :animated, :boolean, default: true
  slot :actions

  def empty_state(assigns) do
    ~H"""
    <div class={[
      "text-center py-16",
      @animated && "animate-fade-in",
      @class
    ]}>
      <div class={[
        "inline-flex items-center justify-center w-20 h-20 rounded-full bg-base-200 border border-base-content/20 mb-4",
        @animated && "animate-bounce-subtle"
      ]}>
        <.icon name={@icon} class="w-10 h-10 text-base-content/40" />
      </div>
      <h3 class="text-xl font-semibold text-base-content/80 mb-2">
        {@title}
      </h3>
      <p :if={@description} class="text-base-content/50 max-w-md mx-auto">
        {@description}
      </p>
      <div :if={@actions != []} class="mt-6">
        {render_slot(@actions)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a status badge for topics.

  ## Examples

      <.status_badge status="draft" />
      <.status_badge status="published" />
  """
  attr :status, :string, required: true
  attr :size, :string, default: "md", values: ~w(sm md)
  attr :class, :string, default: nil

  def status_badge(assigns) do
    ~H"""
    <span class={[
      "rounded-full font-semibold inline-flex items-center gap-1",
      status_badge_size(@size),
      status_badge_color(@status),
      @class
    ]}>
      <.icon :if={@status == "draft"} name="hero-pencil" class={status_icon_size(@size)} />
      <.icon :if={@status == "published"} name="hero-check-circle" class={status_icon_size(@size)} />
      <.icon :if={@status == "archived"} name="hero-archive-box" class={status_icon_size(@size)} />
      {String.capitalize(@status)}
    </span>
    """
  end

  defp status_badge_size("sm"), do: "px-2 py-0.5 text-xs"
  defp status_badge_size("md"), do: "px-3 py-1 text-xs"

  defp status_icon_size("sm"), do: "w-3 h-3"
  defp status_icon_size("md"), do: "w-3.5 h-3.5"

  defp status_badge_color("draft"), do: "bg-warning/10 text-warning border border-warning/20"
  defp status_badge_color("published"), do: "bg-success/10 text-success border border-success/20"

  defp status_badge_color("archived"),
    do: "bg-base-content/10 text-base-content/60 border border-base-content/20"

  defp status_badge_color(_),
    do: "bg-base-content/10 text-base-content/60 border border-base-content/20"

  @doc """
  Renders filter tabs for filtering content.

  ## Examples

      <.filter_tabs
        options={[{"all", "All", "hero-squares-2x2"}, {"draft", "Draft", "hero-pencil"}]}
        selected="all"
        on_select="filter"
        param_name="status"
      />
  """
  attr :options, :list, required: true, doc: "List of {value, label, icon} tuples"
  attr :selected, :string, required: true
  attr :on_select, :string, required: true, doc: "Event name for phx-click"
  attr :param_name, :string, default: "type", doc: "Parameter name for phx-value"
  attr :class, :string, default: nil

  def filter_tabs(assigns) do
    ~H"""
    <div class={["mb-6 sm:mb-8", @class]}>
      <div class="bg-gradient-to-br from-base-200/80 to-base-300/80 backdrop-blur-sm rounded-xl p-2 border border-base-content/10 shadow-xl inline-flex flex-wrap gap-2 w-full sm:w-auto">
        <button
          :for={{value, label, icon} <- @options}
          phx-click={@on_select}
          phx-value-type={if @param_name == "type", do: value}
          phx-value-status={if @param_name == "status", do: value}
          class={[
            "px-4 py-2.5 rounded-lg transition-all duration-200 font-semibold text-sm sm:text-base flex items-center gap-2",
            "focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 focus:ring-offset-base-300",
            if(@selected == value,
              do: "bg-base-100 text-base-content border-2 border-base-content/50",
              else:
                "bg-base-100/50 text-base-content/70 hover:bg-base-100 hover:text-base-content border-2 border-transparent"
            )
          ]}
        >
          <.icon name={icon} class="w-4 h-4" />
          {label}
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a type badge for resources.

  ## Examples

      <.type_badge type="Books" />
      <.type_badge type="Photos" />
  """
  attr :type, :string, required: true
  attr :class, :string, default: nil

  def type_badge(assigns) do
    ~H"""
    <span class={[
      "px-3 py-1.5 font-semibold rounded-lg text-xs border",
      type_badge_color(@type),
      @class
    ]}>
      {@type}
    </span>
    """
  end

  defp type_badge_color("Books"), do: "bg-info/10 text-info border-info/20"
  defp type_badge_color("Photos"), do: "bg-secondary/10 text-secondary border-secondary/20"
  defp type_badge_color("Music"), do: "bg-accent/10 text-accent border-accent/20"
  defp type_badge_color(_), do: "bg-base-content/10 text-base-content/60 border-base-content/20"

  @doc """
  Renders a modal dialog with proper accessibility.

  ## Examples

      <.modal :if={@show_modal} id="my-modal" on_close="close_modal">
        <:title>Modal Title</:title>
        <p>Modal content</p>
      </.modal>
  """
  attr :id, :string, required: true
  attr :on_close, :string, required: true
  attr :size, :string, default: "md", values: ~w(sm md lg xl full)
  attr :class, :string, default: nil
  slot :title
  slot :inner_block, required: true
  slot :footer

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      class="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center p-4 animate-fade-in"
      phx-click={@on_close}
      phx-window-keydown={@on_close}
      phx-key="escape"
      role="dialog"
      aria-modal="true"
      aria-labelledby={"#{@id}-title"}
    >
      <div
        class={[
          "bg-gradient-to-br from-base-200 to-base-300 rounded-2xl w-full overflow-hidden border border-base-content/10 shadow-2xl",
          "max-h-[90vh] sm:max-h-[85vh] flex flex-col",
          modal_size(@size),
          @class
        ]}
        phx-click={%JS{}}
      >
        <%!-- Modal Header --%>
        <div
          :if={@title != []}
          class="flex items-center justify-between p-5 border-b border-base-content/10 bg-base-200/50 shrink-0"
        >
          <h3 id={"#{@id}-title"} class="text-lg font-bold text-base-content">
            {render_slot(@title)}
          </h3>
          <button
            phx-click={@on_close}
            class="p-2 text-base-content/60 hover:text-base-content hover:bg-base-100 rounded-lg transition-all focus:outline-none focus:ring-2 focus:ring-primary"
            aria-label={gettext("Close")}
          >
            <.icon name="hero-x-mark" class="w-6 h-6" />
          </button>
        </div>

        <%!-- Modal Content --%>
        <div class="p-6 overflow-auto flex-1 bg-black/10">
          {render_slot(@inner_block)}
        </div>

        <%!-- Modal Footer --%>
        <div
          :if={@footer != []}
          class="flex gap-3 p-5 border-t border-base-content/10 bg-base-200/50 shrink-0"
        >
          {render_slot(@footer)}
        </div>
      </div>
    </div>
    """
  end

  defp modal_size("sm"), do: "max-w-md"
  defp modal_size("md"), do: "max-w-2xl"
  defp modal_size("lg"), do: "max-w-4xl"
  defp modal_size("xl"), do: "max-w-6xl"
  defp modal_size("full"), do: "max-w-full mx-4 sm:mx-8"

  @doc """
  Renders a page header with title, subtitle, and actions.

  ## Examples

      <.page_header title="Topics">
        <:subtitle>Explore in-depth articles</:subtitle>
        <:actions>
          <.link navigate="/new">New</.link>
        </:actions>
      </.page_header>
  """
  attr :title, :string, required: true
  attr :centered, :boolean, default: false
  attr :class, :string, default: nil
  slot :subtitle
  slot :actions

  def page_header(assigns) do
    ~H"""
    <div class={[
      "mb-6 sm:mb-8",
      @centered && "text-center",
      !@centered && @actions != [] &&
        "flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4",
      @class
    ]}>
      <div>
        <h1 class="text-3xl sm:text-4xl lg:text-5xl font-bold text-base-content mb-3">
          {@title}
        </h1>
        <p :if={@subtitle != []} class="text-base sm:text-lg text-base-content/70">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div :if={@actions != []} class={["flex-none", @centered && "mt-6"]}>
        {render_slot(@actions)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a primary action button with consistent styling.

  ## Examples

      <.primary_button>Save</.primary_button>
      <.primary_button navigate="/new" icon="hero-plus">Add New</.primary_button>
  """
  attr :class, :string, default: nil
  attr :icon, :string, default: nil

  attr :rest, :global,
    include: ~w(href navigate patch method phx-click disabled type phx-disable-with)

  slot :inner_block, required: true

  def primary_button(assigns) do
    ~H"""
    <.button_or_link
      class={[
        "inline-flex items-center justify-center gap-2 px-6 py-3 bg-primary text-primary-content rounded-lg",
        "hover:bg-primary/90 transition-all duration-200 font-semibold shadow-lg shadow-primary/20",
        "focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 focus:ring-offset-base-300",
        "disabled:opacity-50 disabled:cursor-not-allowed",
        @class
      ]}
      {@rest}
    >
      <.icon :if={@icon} name={@icon} class="w-5 h-5" />
      {render_slot(@inner_block)}
    </.button_or_link>
    """
  end

  @doc """
  Renders a secondary action button with consistent styling.
  """
  attr :class, :string, default: nil
  attr :icon, :string, default: nil
  attr :rest, :global, include: ~w(href navigate patch method phx-click disabled type)
  slot :inner_block, required: true

  def secondary_button(assigns) do
    ~H"""
    <.button_or_link
      class={[
        "inline-flex items-center justify-center gap-2 px-6 py-3 bg-base-100 text-base-content rounded-lg",
        "hover:bg-base-200 transition-all duration-200 font-semibold border border-base-content/20",
        "focus:outline-none focus:ring-2 focus:ring-base-content/50 focus:ring-offset-2 focus:ring-offset-base-300",
        "disabled:opacity-50 disabled:cursor-not-allowed",
        @class
      ]}
      {@rest}
    >
      <.icon :if={@icon} name={@icon} class="w-5 h-5" />
      {render_slot(@inner_block)}
    </.button_or_link>
    """
  end

  @doc """
  Renders a danger/destructive button.
  """
  attr :class, :string, default: nil
  attr :icon, :string, default: nil

  attr :rest, :global,
    include: ~w(href navigate patch method phx-click disabled type data-confirm)

  slot :inner_block, required: true

  def danger_button(assigns) do
    ~H"""
    <.button_or_link
      class={[
        "inline-flex items-center justify-center gap-2 px-6 py-3 bg-base-200 text-error rounded-lg",
        "hover:bg-error/20 transition-all duration-200 font-semibold",
        "focus:outline-none focus:ring-2 focus:ring-error/50 focus:ring-offset-2 focus:ring-offset-base-300",
        "disabled:opacity-50 disabled:cursor-not-allowed",
        @class
      ]}
      {@rest}
    >
      <.icon :if={@icon} name={@icon} class="w-5 h-5" />
      {render_slot(@inner_block)}
    </.button_or_link>
    """
  end

  # Helper to render either a link or button based on attributes
  attr :class, :any, required: true

  attr :rest, :global,
    include: ~w(href navigate patch method phx-click disabled type data-confirm phx-value-id)

  slot :inner_block, required: true

  defp button_or_link(assigns) do
    rest = assigns[:rest] || %{}

    if assigns[:href] || assigns[:navigate] || assigns[:patch] ||
         rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders a reference icon based on type.
  """
  attr :type, :string, required: true
  attr :class, :string, default: "w-5 h-5"

  def reference_icon(assigns) do
    ~H"""
    <.icon name={reference_icon_name(@type)} class={@class} />
    """
  end

  @doc """
  Returns the icon name for a reference type.
  """
  def reference_icon_name("book"), do: "hero-book-open"
  def reference_icon_name("talk"), do: "hero-microphone"
  def reference_icon_name("video"), do: "hero-video-camera"
  def reference_icon_name("article"), do: "hero-document-text"
  def reference_icon_name("website"), do: "hero-globe-alt"
  def reference_icon_name(_), do: "hero-link"

  @doc """
  Returns the icon name for a resource type.
  """
  def type_icon("Books"), do: "hero-book-open"
  def type_icon("Photos"), do: "hero-photo"
  def type_icon("Music"), do: "hero-musical-note"
  def type_icon(_), do: "hero-document"

  @doc """
  Renders a skeleton loading placeholder.

  ## Examples

      <.skeleton class="h-4 w-32" />
      <.skeleton class="h-20 w-full rounded-lg" />
  """
  attr :class, :string, default: "h-4 w-full"

  def skeleton(assigns) do
    ~H"""
    <div class={["skeleton", @class]} aria-hidden="true"></div>
    """
  end

  @doc """
  Renders a loading spinner.

  ## Examples

      <.spinner />
      <.spinner size="lg" />
  """
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :class, :string, default: nil

  def spinner(assigns) do
    ~H"""
    <div class={["animate-spin", spinner_size(@size), @class]} aria-label={gettext("Loading")}>
      <.icon name="hero-arrow-path" class="w-full h-full" />
    </div>
    """
  end

  defp spinner_size("sm"), do: "w-4 h-4"
  defp spinner_size("md"), do: "w-6 h-6"
  defp spinner_size("lg"), do: "w-8 h-8"

  @doc """
  Renders a loading state with spinner and optional message.

  ## Examples

      <.loading_state />
      <.loading_state message="Loading talks..." />
  """
  attr :message, :string, default: nil
  attr :class, :string, default: nil

  def loading_state(assigns) do
    ~H"""
    <div class={["flex flex-col items-center justify-center py-12", @class]}>
      <.spinner size="lg" class="text-primary mb-4" />
      <p :if={@message} class="text-base-content/60">{@message}</p>
    </div>
    """
  end

  @doc """
  Renders a skeleton card for topics list loading state.

  ## Examples

      <.topic_card_skeleton />
  """
  attr :class, :string, default: nil

  def topic_card_skeleton(assigns) do
    ~H"""
    <div
      class={[
        "bg-gradient-to-br from-base-200 to-base-300 rounded-xl border border-base-content/10 p-4 sm:p-6",
        @class
      ]}
      aria-hidden="true"
    >
      <%!-- Title skeleton --%>
      <div class="skeleton h-6 w-3/4 mb-3 rounded"></div>
      <%!-- Content preview skeleton --%>
      <div class="space-y-2 mb-4">
        <div class="skeleton h-4 w-full rounded"></div>
        <div class="skeleton h-4 w-5/6 rounded"></div>
        <div class="skeleton h-4 w-4/6 rounded"></div>
      </div>
      <%!-- Meta info skeleton --%>
      <div class="flex items-center justify-between pt-4 border-t border-base-content/10">
        <div class="skeleton h-4 w-24 rounded"></div>
        <div class="flex gap-3">
          <div class="skeleton h-4 w-12 rounded"></div>
          <div class="skeleton h-4 w-20 rounded"></div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a skeleton grid for topics list loading state.

  ## Examples

      <.topics_skeleton_grid count={6} />
  """
  attr :count, :integer, default: 6
  attr :class, :string, default: nil

  def topics_skeleton_grid(assigns) do
    ~H"""
    <div class={["grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6", @class]}>
      <.topic_card_skeleton :for={_ <- 1..@count} />
    </div>
    """
  end

  @doc """
  Renders a skeleton for topic content loading state.

  ## Examples

      <.topic_content_skeleton />
  """
  attr :class, :string, default: nil

  def topic_content_skeleton(assigns) do
    ~H"""
    <div class={["space-y-4", @class]} aria-hidden="true">
      <%!-- Title skeleton --%>
      <div class="skeleton h-10 w-2/3 rounded"></div>
      <%!-- Meta info skeleton --%>
      <div class="flex gap-4">
        <div class="skeleton h-4 w-32 rounded"></div>
        <div class="skeleton h-4 w-24 rounded"></div>
        <div class="skeleton h-4 w-20 rounded"></div>
      </div>
      <%!-- Content skeleton --%>
      <div class="space-y-3 pt-4">
        <div class="skeleton h-4 w-full rounded"></div>
        <div class="skeleton h-4 w-full rounded"></div>
        <div class="skeleton h-4 w-5/6 rounded"></div>
        <div class="skeleton h-4 w-full rounded"></div>
        <div class="skeleton h-4 w-4/5 rounded"></div>
        <div class="skeleton h-4 w-full rounded"></div>
        <div class="skeleton h-4 w-3/4 rounded"></div>
      </div>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="relative inline-flex items-center justify-center">
      <%!-- Button to switch to Light mode (visible when in Dark mode) --%>
      <button
        type="button"
        class="btn btn-ghost btn-sm btn-circle hidden [[data-theme=dark]_&]:inline-flex text-base-content/70 hover:text-base-content transition-colors"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
        aria-label={gettext("Switch to light theme")}
      >
        <.icon name="hero-sun" class="w-5 h-5" />
      </button>

      <%!-- Button to switch to Dark mode (visible when in Light mode) --%>
      <button
        type="button"
        class="btn btn-ghost btn-sm btn-circle inline-flex [[data-theme=dark]_&]:hidden text-base-content/70 hover:text-base-content transition-colors"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
        aria-label={gettext("Switch to dark theme")}
      >
        <.icon name="hero-moon" class="w-5 h-5" />
      </button>
    </div>
    """
  end
end

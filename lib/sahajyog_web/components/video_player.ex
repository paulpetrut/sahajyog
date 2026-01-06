defmodule SahajyogWeb.VideoPlayer do
  @moduledoc """
  Component for rendering optimized video players with browser caching support.
  Supports YouTube and Vimeo providers with locale-aware subtitle configuration.
  """
  use SahajyogWeb, :html

  @doc """
  Optimized video player component with browser caching support.

  Uses phx-update="ignore" to persist iframe across LiveView updates,
  and browser loading hints for priority loading.
  """
  attr :video_id, :string, required: true
  attr :provider, :atom, default: :youtube
  attr :locale, :string, default: "en"
  attr :class, :string, default: "w-full h-full"
  attr :container_class, :string, default: "aspect-video bg-black"
  attr :dom_id, :string, default: nil
  attr :title, :string, default: nil

  def optimized_video_player(assigns) do
    # Generate unique ID if not provided
    assigns =
      assign_new(assigns, :dom_id, fn ->
        "video-player-#{assigns.video_id}"
      end)

    ~H"""
    <div
      id={@dom_id}
      phx-update="ignore"
      class={@container_class}
      style="opacity: 1 !important; visibility: visible !important;"
    >
      <iframe
        src={Sahajyog.VideoProvider.embed_url(@video_id, @provider, @locale)}
        class={@class}
        frameborder="0"
        loading="eager"
        importance="high"
        allow="autoplay; fullscreen; picture-in-picture; clipboard-write; encrypted-media; web-share"
        referrerpolicy="strict-origin-when-cross-origin"
        title={@title || gettext("Video player")}
      >
      </iframe>
    </div>
    """
  end
end

defmodule SahajyogWeb.VideoPlayer do
  use SahajyogWeb, :html

  attr :video_id, :string, required: true
  attr :provider, :atom, required: true
  attr :locale, :string, default: "en"
  attr :class, :string, default: "w-full h-full"
  attr :title, :string, default: nil
  attr :dom_id, :string, default: nil

  def video_player(assigns) do
    ~H"""
    <div class="relative w-full h-full group">
      <%!-- Loading placeholder shown while iframe loads --%>
      <div class="absolute inset-0 bg-base-300 flex items-center justify-center z-0">
        <div class="text-center">
          <div class="w-12 h-12 border-4 border-primary/30 border-t-primary rounded-full animate-spin mx-auto mb-3">
          </div>
          <p class="text-base-content/60 text-sm">{gettext("Loading video...")}</p>
        </div>
      </div>
      <iframe
        id={@dom_id}
        src={Sahajyog.VideoProvider.embed_url(@video_id, @provider, @locale)}
        class="absolute inset-0 w-full h-full z-10"
        frameborder="0"
        allow="autoplay; fullscreen; picture-in-picture; clipboard-write; encrypted-media; web-share"
        allowfullscreen
        referrerpolicy="strict-origin-when-cross-origin"
        title={@title || gettext("Video player")}
      >
      </iframe>
    </div>
    """
  end
end

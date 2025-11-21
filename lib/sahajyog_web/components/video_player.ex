defmodule SahajyogWeb.VideoPlayer do
  use Phoenix.Component

  attr :video_id, :string, required: true
  attr :provider, :atom, required: true
  attr :locale, :string, default: "en"
  attr :class, :string, default: "w-full h-full"

  def video_player(assigns) do
    ~H"""
    <iframe
      src={Sahajyog.VideoProvider.embed_url(@video_id, @provider, @locale)}
      class={@class}
      frameborder="0"
      allow="autoplay; fullscreen; picture-in-picture; clipboard-write; encrypted-media; web-share"
      allowfullscreen
      referrerpolicy="strict-origin-when-cross-origin"
    >
    </iframe>
    """
  end
end

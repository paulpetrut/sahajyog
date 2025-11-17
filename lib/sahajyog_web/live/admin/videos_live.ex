defmodule SahajyogWeb.Admin.VideosLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Content
  alias Sahajyog.Content.Video
  alias Sahajyog.YouTube

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Manage Videos")
     |> assign(:videos, Content.list_videos_ordered())
     |> assign(:form, nil)
     |> assign(:editing_video, nil)
     |> assign(:fetching_metadata, false)}
  end

  @impl true
  def handle_event("new", _params, socket) do
    # Start with empty form - step number will be set when category is selected
    changeset = Content.change_video(%Video{})

    {:noreply,
     socket
     |> assign(:editing_video, nil)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    video = Content.get_video!(id)
    changeset = Content.change_video(video)

    {:noreply,
     socket
     |> assign(:editing_video, video)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    video = Content.get_video!(id)
    {:ok, _} = Content.delete_video(video)

    {:noreply,
     socket
     |> assign(:videos, Content.list_videos_ordered())
     |> put_flash(:info, "Video deleted successfully")}
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    {:noreply,
     socket
     |> assign(:form, nil)
     |> assign(:editing_video, nil)}
  end

  @impl true
  def handle_event("validate", %{"video" => video_params}, socket) do
    video = socket.assigns.editing_video || %Video{}

    # Auto-fill step_number when category is selected and step_number is empty
    video_params =
      if video_params["category"] && video_params["category"] != "" &&
           (video_params["step_number"] == nil || video_params["step_number"] == "") do
        next_step = Content.next_step_number(video_params["category"])
        Map.put(video_params, "step_number", to_string(next_step))
      else
        video_params
      end

    # Check if URL changed and fetch metadata
    current_url = if socket.assigns.form, do: socket.assigns.form.params["url"], else: nil
    new_url = video_params["url"]

    socket =
      if new_url && new_url != "" && new_url != current_url &&
           String.contains?(new_url, "youtube") do
        fetch_youtube_metadata(socket, video_params)
      else
        changeset =
          video
          |> Content.change_video(video_params)
          |> Map.put(:action, :validate)

        assign(socket, :form, to_form(changeset))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("fetch_metadata", %{"url" => url}, socket) do
    video_params = socket.assigns.form.params

    socket =
      if url && url != "" && String.contains?(url, "youtube") do
        fetch_youtube_metadata(socket, Map.put(video_params, "url", url))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"video" => video_params}, socket) do
    save_video(socket, socket.assigns.editing_video, video_params)
  end

  defp fetch_youtube_metadata(socket, video_params) do
    url = video_params["url"]

    case YouTube.fetch_metadata(url) do
      {:ok, metadata} ->
        updated_params =
          video_params
          |> maybe_put_if_empty("title", metadata.title)
          |> maybe_put_if_empty("thumbnail_url", metadata.thumbnail_url)

        video = socket.assigns.editing_video || %Video{}

        changeset =
          video
          |> Content.change_video(updated_params)
          |> Map.put(:action, :validate)

        socket
        |> assign(:form, to_form(changeset))
        |> put_flash(:info, "Fetched video metadata from YouTube")

      {:error, _} ->
        changeset =
          (socket.assigns.editing_video || %Video{})
          |> Content.change_video(video_params)
          |> Map.put(:action, :validate)

        socket
        |> assign(:form, to_form(changeset))
        |> put_flash(:error, "Could not fetch video metadata")
    end
  end

  defp maybe_put_if_empty(params, key, value) do
    if value && (params[key] == nil || params[key] == "") do
      Map.put(params, key, value)
    else
      params
    end
  end

  defp save_video(socket, nil, video_params) do
    case Content.create_video(video_params) do
      {:ok, _video} ->
        {:noreply,
         socket
         |> assign(:videos, Content.list_videos_ordered())
         |> assign(:form, nil)
         |> put_flash(:info, "Video created successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_video(socket, video, video_params) do
    case Content.update_video(video, video_params) do
      {:ok, _video} ->
        {:noreply,
         socket
         |> assign(:videos, Content.list_videos_ordered())
         |> assign(:form, nil)
         |> assign(:editing_video, nil)
         |> put_flash(:info, "Video updated successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 py-12 px-4">
      <div class="max-w-7xl mx-auto">
        <div class="flex justify-between items-center mb-8">
          <h1 class="text-4xl font-bold text-white">Manage Videos</h1>
          <button
            :if={!@form}
            phx-click="new"
            class="px-6 py-3 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors font-semibold shadow-lg"
          >
            + Add New Video
          </button>
        </div>

        <%!-- Video Form --%>
        <div :if={@form} class="bg-gray-800 rounded-xl shadow-lg p-8 mb-8 border border-gray-700">
          <h2 class="text-2xl font-bold text-white mb-6">
            {(@editing_video && "Edit Video") || "New Video"}
          </h2>

          <.form for={@form} id="video-form" phx-change="validate" phx-submit="save">
            <div class="space-y-6">
              <div>
                <.input
                  field={@form[:title]}
                  type="text"
                  label="Title"
                  placeholder="Enter video title"
                />
              </div>

              <div>
                <.input
                  field={@form[:url]}
                  type="text"
                  label="Video URL"
                  placeholder="https://youtube.com/watch?v=..."
                />
                <button
                  type="button"
                  phx-click="fetch_metadata"
                  phx-value-url={@form[:url].value}
                  class="mt-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm font-medium"
                >
                  <.icon name="hero-arrow-down-tray" class="w-4 h-4 inline mr-1" /> Fetch Video Info
                </button>
              </div>

              <div>
                <.input
                  field={@form[:category]}
                  type="select"
                  label="Category"
                  options={Video.categories()}
                  prompt="Select a category"
                />
              </div>

              <div>
                <.input
                  field={@form[:step_number]}
                  type="number"
                  label="Step Number"
                  placeholder="Order in sequence"
                />
                <p class="text-sm text-gray-400 mt-1">
                  Videos at this position and higher in the same category will shift up automatically
                </p>
              </div>

              <div>
                <.input
                  field={@form[:description]}
                  type="textarea"
                  label="Description"
                  placeholder="Enter video description (optional)"
                />
              </div>

              <div>
                <.input
                  field={@form[:thumbnail_url]}
                  type="text"
                  label="Thumbnail URL"
                  placeholder="https://... (optional)"
                />
              </div>

              <div>
                <.input
                  field={@form[:duration]}
                  type="text"
                  label="Duration"
                  placeholder="e.g., 10:30 (optional)"
                />
              </div>

              <div class="flex gap-4 pt-4">
                <button
                  type="submit"
                  class="px-6 py-3 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors font-semibold"
                >
                  {(@editing_video && "Update Video") || "Create Video"}
                </button>
                <button
                  type="button"
                  phx-click="cancel"
                  class="px-6 py-3 bg-gray-700 text-white rounded-lg hover:bg-gray-600 transition-colors font-semibold"
                >
                  Cancel
                </button>
              </div>
            </div>
          </.form>
        </div>

        <%!-- Videos List --%>
        <div class="space-y-6">
          <%= for category <- Video.categories() do %>
            <div class="bg-gray-800 rounded-xl shadow-lg p-6 border border-gray-700">
              <h2 class="text-2xl font-bold text-white mb-4">{category}</h2>

              <div class="space-y-4">
                <%= for video <- Enum.filter(@videos, &(&1.category == category)) do %>
                  <div class="flex items-start gap-4 p-4 bg-gray-700 rounded-lg hover:bg-gray-600 transition-colors">
                    <div :if={video.thumbnail_url} class="flex-shrink-0">
                      <img
                        src={video.thumbnail_url}
                        alt={video.title}
                        class="w-32 h-20 object-cover rounded"
                      />
                    </div>

                    <div class="flex-1 min-w-0">
                      <div class="flex items-center gap-2">
                        <span
                          :if={video.step_number}
                          class="px-2 py-1 bg-orange-600 text-white text-xs font-bold rounded"
                        >
                          #{video.step_number}
                        </span>
                        <h3 class="text-lg font-semibold text-white truncate">{video.title}</h3>
                      </div>
                      <p :if={video.description} class="text-sm text-gray-300 mt-1 line-clamp-2">
                        {video.description}
                      </p>
                      <div class="flex items-center gap-4 mt-2 text-sm text-gray-400">
                        <span :if={video.duration}>Duration: {video.duration}</span>
                        <a
                          href={video.url}
                          target="_blank"
                          class="text-orange-400 hover:text-orange-300"
                        >
                          View Video →
                        </a>
                      </div>
                    </div>

                    <div class="flex gap-2">
                      <button
                        phx-click="edit"
                        phx-value-id={video.id}
                        class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors text-sm font-medium"
                      >
                        Edit
                      </button>
                      <button
                        phx-click="delete"
                        phx-value-id={video.id}
                        data-confirm="Are you sure you want to delete this video?"
                        class="px-4 py-2 text-white rounded transition-colors text-sm font-medium"
                        style="background-color: #d14545;"
                        onmouseover="this.style.backgroundColor='#b83030'"
                        onmouseout="this.style.backgroundColor='#d14545'"
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                <% end %>

                <div
                  :if={Enum.filter(@videos, &(&1.category == category)) == []}
                  class="text-center py-8 text-gray-400"
                >
                  No videos in this category yet
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end

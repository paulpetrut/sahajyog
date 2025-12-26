defmodule SahajyogWeb.Admin.VideosLive do
  use SahajyogWeb, :live_view

  import SahajyogWeb.AdminNav

  alias Sahajyog.Content
  alias Sahajyog.Content.Video
  alias Sahajyog.VideoProvider

  @impl true
  def mount(_params, _session, socket) do
    pool_videos = Content.list_welcome_pool_videos()
    pool_size = length(pool_videos)

    today_position =
      if pool_size > 0,
        do: Content.calculate_daily_position(Date.utc_today(), pool_size),
        else: nil

    {:ok,
     socket
     |> assign(:page_title, "Admin Videos")
     |> assign(:videos, Content.list_videos_ordered())
     |> assign(:pool_videos, pool_videos)
     |> assign(:pool_size, pool_size)
     |> assign(:today_position, today_position)
     |> assign(:form, nil)
     |> assign(:editing_video, nil)
     |> assign(:fetching_metadata, false)}
  end

  # All handle_event clauses grouped together
  @impl true
  def handle_event("new", _params, socket) do
    changeset = Content.change_video(%Video{})

    {:noreply,
     socket
     |> assign(:editing_video, nil)
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    video = Content.get_video!(id)
    changeset = Content.change_video(video)

    {:noreply,
     socket
     |> assign(:editing_video, video)
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    video = Content.get_video!(id)
    {:ok, _} = Content.delete_video(video)

    {:noreply,
     socket
     |> assign(:videos, Content.list_videos_ordered())
     |> refresh_pool_data()
     |> put_flash(:info, "Video deleted successfully")}
  end

  def handle_event("cancel", _params, socket) do
    {:noreply,
     socket
     |> assign(:form, nil)
     |> assign(:editing_video, nil)}
  end

  def handle_event("validate", %{"video" => video_params}, socket) do
    video = socket.assigns.editing_video || %Video{}

    video_params =
      if video_params["category"] && video_params["category"] != "" &&
           (video_params["step_number"] == nil || video_params["step_number"] == "") do
        next_step = Content.next_step_number(video_params["category"])
        Map.put(video_params, "step_number", to_string(next_step))
      else
        video_params
      end

    video_params =
      if video_params["url"] && video_params["url"] != "" do
        provider = VideoProvider.detect_provider(video_params["url"])
        Map.put(video_params, "provider", to_string(provider))
      else
        video_params
      end

    current_url = if socket.assigns.form, do: socket.assigns.form.params["url"], else: nil
    new_url = video_params["url"]

    socket =
      if new_url && new_url != "" && new_url != current_url do
        provider =
          case video_params["provider"] do
            "youtube" -> :youtube
            "vimeo" -> :vimeo
            _ -> nil
          end

        if provider in [:youtube, :vimeo] do
          fetch_video_metadata(socket, video_params, provider)
        else
          changeset =
            video
            |> Content.change_video(video_params)
            |> Map.put(:action, :validate)

          socket
          |> assign(:form, to_form(changeset))
          |> put_flash(:error, "Unsupported video provider. Please use YouTube or Vimeo.")
        end
      else
        changeset =
          video
          |> Content.change_video(video_params)
          |> Map.put(:action, :validate)

        assign(socket, :form, to_form(changeset))
      end

    {:noreply, socket}
  end

  def handle_event("fetch_metadata", %{"url" => url}, socket) do
    video_params = socket.assigns.form.params

    socket =
      if url && url != "" do
        provider = VideoProvider.detect_provider(url)

        video_params =
          video_params
          |> Map.put("url", url)
          |> Map.put("provider", to_string(provider))

        if provider in [:youtube, :vimeo] do
          fetch_video_metadata(socket, video_params, provider)
        else
          socket
          |> put_flash(:error, "Unsupported video provider. Please use YouTube or Vimeo.")
        end
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("save", %{"video" => video_params}, socket) do
    video_params =
      if video_params["url"] && video_params["url"] != "" do
        provider = VideoProvider.detect_provider(video_params["url"])
        Map.put(video_params, "provider", to_string(provider))
      else
        video_params
      end

    save_video(socket, socket.assigns.editing_video, video_params)
  end

  # Pool management event handlers
  def handle_event("add_to_pool", %{"id" => id}, socket) do
    video_id = String.to_integer(id)

    case Content.add_to_welcome_pool(video_id) do
      {:ok, _video} ->
        {:noreply,
         socket
         |> assign(:videos, Content.list_videos_ordered())
         |> refresh_pool_data()
         |> put_flash(:info, gettext("Video added to Welcome pool"))}

      {:error, :pool_full} ->
        {:noreply, put_flash(socket, :error, gettext("Welcome pool is full (maximum 31 videos)"))}

      {:error, :already_in_pool} ->
        {:noreply, put_flash(socket, :error, gettext("Video is already in the pool"))}

      {:error, :invalid_category} ->
        {:noreply,
         put_flash(socket, :error, gettext("Only Welcome videos can be added to the pool"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to add video to pool"))}
    end
  end

  def handle_event("remove_from_pool", %{"id" => id}, socket) do
    video_id = String.to_integer(id)

    case Content.remove_from_welcome_pool(video_id) do
      {:ok, _video} ->
        {:noreply,
         socket
         |> assign(:videos, Content.list_videos_ordered())
         |> refresh_pool_data()
         |> put_flash(:info, gettext("Video removed from Welcome pool"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to remove video from pool"))}
    end
  end

  def handle_event("shuffle_pool", _params, socket) do
    case Content.shuffle_welcome_pool() do
      {:ok, _videos} ->
        {:noreply,
         socket
         |> refresh_pool_data()
         |> put_flash(:info, gettext("Welcome pool shuffled successfully"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to shuffle pool"))}
    end
  end

  def handle_event("reorder_pool", %{"ids" => ids}, socket) do
    video_ids = Enum.map(ids, &String.to_integer/1)

    case Content.reorder_welcome_pool(video_ids) do
      {:ok, _videos} ->
        {:noreply, refresh_pool_data(socket)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to reorder pool"))}
    end
  end

  # Private helper functions
  defp fetch_video_metadata(socket, video_params, provider) do
    url = video_params["url"]
    provider_name = provider |> to_string() |> String.capitalize()

    case VideoProvider.fetch_metadata(url, provider) do
      {:ok, metadata} ->
        updated_params =
          video_params
          |> maybe_put_if_empty("title", metadata.title)
          |> maybe_put_if_empty("thumbnail_url", metadata.thumbnail_url)
          |> maybe_put_if_empty("duration", metadata[:duration])

        video = socket.assigns.editing_video || %Video{}

        changeset =
          video
          |> Content.change_video(updated_params)
          |> Map.put(:action, :validate)

        socket
        |> assign(:form, to_form(changeset))
        |> put_flash(:info, "Fetched video metadata from #{provider_name}")

      {:error, _} ->
        changeset =
          (socket.assigns.editing_video || %Video{})
          |> Content.change_video(video_params)
          |> Map.put(:action, :validate)

        socket
        |> assign(:form, to_form(changeset))
        |> put_flash(:error, "Could not fetch video metadata from #{provider_name}")
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

  defp refresh_pool_data(socket) do
    pool_videos = Content.list_welcome_pool_videos()
    pool_size = length(pool_videos)

    today_position =
      if pool_size > 0,
        do: Content.calculate_daily_position(Date.utc_today(), pool_size),
        else: nil

    socket
    |> assign(:pool_videos, pool_videos)
    |> assign(:pool_size, pool_size)
    |> assign(:today_position, today_position)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_container>
      <.admin_nav current_page={:videos} />

      <div class="max-w-7xl mx-auto px-4 py-8">
        <.page_header title={gettext("Manage Videos")}>
          <:actions>
            <.primary_button :if={!@form} phx-click="new" icon="hero-plus">
              {gettext("Add New Video")}
            </.primary_button>
          </:actions>
        </.page_header>

        <%!-- Welcome Pool Management Section --%>
        <.card size="lg" class="mb-8">
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
            <div>
              <h2 class="text-2xl font-bold text-base-content">
                {gettext("Welcome Pool")}
              </h2>
              <p class="text-base-content/60 mt-1">
                {gettext("Daily rotation pool - %{count}/31 videos", count: @pool_size)}
              </p>
            </div>
            <div class="flex gap-2">
              <button
                :if={@pool_size > 1}
                phx-click="shuffle_pool"
                class="px-4 py-2 bg-info text-info-content rounded-lg hover:bg-info/90 transition-colors text-sm font-medium focus:outline-none focus:ring-2 focus:ring-info flex items-center gap-2"
              >
                <.icon name="hero-arrow-path" class="w-4 h-4" />
                {gettext("Shuffle")}
              </button>
            </div>
          </div>

          <%!-- Current Day Indicator --%>
          <div
            :if={@today_position}
            class="mb-4 p-3 bg-success/10 border border-success/20 rounded-lg"
          >
            <div class="flex items-center gap-2 text-success">
              <.icon name="hero-calendar-days" class="w-5 h-5" />
              <span class="font-medium">
                {gettext("Today's video: Position %{position}", position: @today_position)}
              </span>
            </div>
          </div>

          <%!-- Pool Videos List with Drag-and-Drop --%>
          <div
            :if={@pool_videos != []}
            id="pool-videos"
            phx-hook="PoolSortable"
            phx-update="ignore"
            class="space-y-2"
          >
            <div
              :for={video <- @pool_videos}
              id={"pool-video-#{video.id}"}
              data-id={video.id}
              class={[
                "flex items-center gap-3 p-3 bg-base-100 rounded-lg border transition-all cursor-move",
                if(video.pool_position == @today_position,
                  do: "border-success/50 bg-success/5",
                  else: "border-base-content/10 hover:border-primary/30"
                )
              ]}
            >
              <div class="flex-shrink-0 text-base-content/40 cursor-grab">
                <.icon name="hero-bars-3" class="w-5 h-5" />
              </div>

              <div class="flex-shrink-0 w-8 h-8 flex items-center justify-center rounded-full bg-primary/10 text-primary font-bold text-sm">
                {video.pool_position}
              </div>

              <div :if={video.thumbnail_url} class="flex-shrink-0">
                <img
                  src={video.thumbnail_url}
                  alt={video.title}
                  class="w-16 h-10 object-cover rounded"
                />
              </div>

              <div class="flex-1 min-w-0">
                <h4 class="font-medium text-base-content truncate">{video.title}</h4>
                <p :if={video.duration} class="text-xs text-base-content/60">{video.duration}</p>
              </div>

              <div :if={video.pool_position == @today_position} class="flex-shrink-0">
                <span class="px-2 py-1 bg-success/20 text-success text-xs font-semibold rounded">
                  {gettext("Playing Today")}
                </span>
              </div>

              <button
                phx-click="remove_from_pool"
                phx-value-id={video.id}
                class="flex-shrink-0 p-2 text-error/70 hover:text-error hover:bg-error/10 rounded-lg transition-colors focus:outline-none focus:ring-2 focus:ring-error/50"
                title={gettext("Remove from pool")}
              >
                <.icon name="hero-x-mark" class="w-5 h-5" />
              </button>
            </div>
          </div>

          <%!-- Empty Pool State --%>
          <div :if={@pool_videos == []} class="text-center py-8 text-base-content/50">
            <.icon name="hero-film" class="w-12 h-12 mx-auto mb-3 opacity-50" />
            <p>{gettext("No videos in the Welcome pool yet")}</p>
            <p class="text-sm mt-1">{gettext("Add Welcome videos to the pool below")}</p>
          </div>
        </.card>

        <%!-- Video Form --%>
        <.card :if={@form} size="lg" class="mb-8">
          <h2 class="text-2xl font-bold text-base-content mb-6">
            {(@editing_video && gettext("Edit Video")) || gettext("New Video")}
          </h2>

          <.form for={@form} id="video-form" phx-change="validate" phx-submit="save">
            <div class="space-y-6">
              <div>
                <.input
                  field={@form[:title]}
                  type="text"
                  label={gettext("Title")}
                  placeholder={gettext("Enter video title")}
                />
              </div>

              <div>
                <.input
                  field={@form[:url]}
                  type="text"
                  label={gettext("Video URL")}
                  placeholder="https://youtube.com/watch?v=... or https://vimeo.com/..."
                />
                <button
                  type="button"
                  phx-click="fetch_metadata"
                  phx-value-url={@form[:url].value}
                  class="mt-2 px-4 py-2 bg-info text-info-content rounded-lg hover:bg-info/90 transition-colors text-sm font-medium focus:outline-none focus:ring-2 focus:ring-info"
                >
                  <.icon name="hero-arrow-down-tray" class="w-4 h-4 inline mr-1" />
                  {gettext("Fetch Video Info")}
                </button>
                <p :if={@form[:provider].value} class="text-sm text-base-content/60 mt-1">
                  {gettext("Provider")}: {String.capitalize(@form[:provider].value || "unknown")}
                </p>
              </div>

              <div>
                <.input
                  field={@form[:category]}
                  type="select"
                  label={gettext("Category")}
                  options={Video.categories()}
                  prompt={gettext("Select a category")}
                />
              </div>

              <div>
                <.input
                  field={@form[:step_number]}
                  type="number"
                  label={gettext("Step Number")}
                  placeholder={gettext("Order in sequence")}
                />
                <p class="text-sm text-base-content/60 mt-1">
                  {gettext(
                    "Videos at this position and higher in the same category will shift up automatically"
                  )}
                </p>
              </div>

              <div>
                <.input
                  field={@form[:description]}
                  type="textarea"
                  label={gettext("Description")}
                  placeholder={gettext("Enter video description (optional)")}
                />
              </div>

              <div>
                <.input
                  field={@form[:thumbnail_url]}
                  type="text"
                  label={gettext("Thumbnail URL")}
                  placeholder="https://... (optional)"
                />
              </div>

              <div>
                <.input
                  field={@form[:duration]}
                  type="text"
                  label={gettext("Duration")}
                  placeholder="e.g., 10:30 (optional)"
                />
              </div>

              <div class="flex gap-4 pt-4">
                <.primary_button type="submit">
                  {(@editing_video && gettext("Update Video")) || gettext("Create Video")}
                </.primary_button>
                <.secondary_button type="button" phx-click="cancel">
                  {gettext("Cancel")}
                </.secondary_button>
              </div>
            </div>
          </.form>
        </.card>

        <%!-- Videos List --%>
        <div class="space-y-6">
          <%= for category <- Video.categories() do %>
            <.card class="p-6">
              <h2 class="text-2xl font-bold text-base-content mb-4">{category}</h2>

              <div class="space-y-4">
                <%= for video <- Enum.filter(@videos, &(&1.category == category)) do %>
                  <div class="flex items-start gap-4 p-4 bg-base-100 rounded-lg hover:bg-base-200 transition-colors">
                    <div :if={video.thumbnail_url} class="flex-shrink-0">
                      <img
                        src={video.thumbnail_url}
                        alt={video.title}
                        class="w-32 h-20 object-cover rounded"
                      />
                    </div>

                    <div class="flex-1 min-w-0">
                      <div class="flex items-center gap-2 flex-wrap">
                        <span
                          :if={video.step_number}
                          class="px-2 py-1 bg-warning text-warning-content text-xs font-bold rounded"
                        >
                          #{video.step_number}
                        </span>
                        <span
                          :if={video.in_pool && video.category == "Welcome"}
                          class="px-2 py-1 bg-success/20 text-success text-xs font-semibold rounded"
                        >
                          {gettext("In Pool")} #{video.pool_position}
                        </span>
                        <h3 class="text-lg font-semibold text-base-content truncate">
                          {video.title}
                        </h3>
                      </div>
                      <p
                        :if={video.description}
                        class="text-sm text-base-content/70 mt-1 line-clamp-2"
                      >
                        {video.description}
                      </p>
                      <div class="flex items-center gap-4 mt-2 text-sm text-base-content/60">
                        <span :if={video.duration}>{gettext("Duration")}: {video.duration}</span>
                        <a
                          href={video.url}
                          target="_blank"
                          class="text-warning hover:text-warning/80 focus:outline-none focus:ring-2 focus:ring-warning rounded"
                        >
                          {gettext("View Video")} →
                        </a>
                      </div>
                    </div>

                    <div class="flex gap-2 flex-wrap justify-end">
                      <%!-- Pool management buttons for Welcome videos --%>
                      <%= if video.category == "Welcome" do %>
                        <%= if video.in_pool do %>
                          <button
                            phx-click="remove_from_pool"
                            phx-value-id={video.id}
                            class="px-3 py-2 bg-base-200 text-base-content/70 rounded hover:bg-base-300 transition-colors text-sm font-medium focus:outline-none focus:ring-2 focus:ring-base-content/30 flex items-center gap-1"
                          >
                            <.icon name="hero-minus-circle" class="w-4 h-4" />
                            {gettext("Remove from Pool")}
                          </button>
                        <% else %>
                          <button
                            phx-click="add_to_pool"
                            phx-value-id={video.id}
                            disabled={@pool_size >= 31}
                            class={[
                              "px-3 py-2 rounded transition-colors text-sm font-medium focus:outline-none focus:ring-2 flex items-center gap-1",
                              if(@pool_size >= 31,
                                do: "bg-base-200 text-base-content/40 cursor-not-allowed",
                                else:
                                  "bg-success/20 text-success hover:bg-success/30 focus:ring-success/50"
                              )
                            ]}
                          >
                            <.icon name="hero-plus-circle" class="w-4 h-4" />
                            {gettext("Add to Pool")}
                          </button>
                        <% end %>
                      <% end %>
                      <button
                        phx-click="edit"
                        phx-value-id={video.id}
                        class="px-4 py-2 bg-primary text-primary-content rounded hover:bg-primary/90 transition-colors text-sm font-medium focus:outline-none focus:ring-2 focus:ring-primary"
                      >
                        {gettext("Edit")}
                      </button>
                      <button
                        phx-click="delete"
                        phx-value-id={video.id}
                        data-confirm={gettext("Are you sure you want to delete this video?")}
                        class="px-4 py-2 bg-base-200 text-error rounded hover:bg-error/20 transition-colors text-sm font-medium focus:outline-none focus:ring-2 focus:ring-error/50"
                      >
                        {gettext("Delete")}
                      </button>
                    </div>
                  </div>
                <% end %>

                <div
                  :if={Enum.filter(@videos, &(&1.category == category)) == []}
                  class="text-center py-8 text-base-content/50"
                >
                  {gettext("No videos in this category yet")}
                </div>
              </div>
            </.card>
          <% end %>
        </div>
      </div>
    </.page_container>
    """
  end
end

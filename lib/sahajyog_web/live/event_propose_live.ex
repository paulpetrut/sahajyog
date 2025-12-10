defmodule SahajyogWeb.EventProposeLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Events
  alias Sahajyog.Resources.R2Storage

  # 500MB max file size for video uploads
  @max_video_size 500_000_000
  # 10MB max file size for invitation materials
  @max_invitation_size 10_485_760

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    if !Sahajyog.Accounts.User.profile_complete?(user) do
      encoded_return = URI.encode_www_form(~p"/events/propose")

      {:ok,
       socket
       |> put_flash(
         :error,
         gettext(
           "Please complete your profile (First Name, Last Name, Phone Number) before proposing an event."
         )
       )
       |> push_navigate(to: ~p"/users/settings?return_to=#{encoded_return}")}
    else
      proposal = %Sahajyog.Events.EventProposal{}
      changeset = Events.change_proposal(proposal)

      {:ok,
       socket
       |> assign(:page_title, "Propose Event")
       |> assign(:proposal, proposal)
       |> assign(:form, to_form(changeset))
       |> assign(:uploaded_invitations, [])
       |> allow_upload(:video,
         accept: ~w(.mp4 .webm .mov),
         max_entries: 1,
         max_file_size: @max_video_size,
         auto_upload: true
       )
       |> allow_upload(:invitation_materials,
         accept: ~w(.jpg .jpeg .png .pdf),
         max_entries: 10,
         max_file_size: @max_invitation_size,
         auto_upload: true
       )}
    end
  end

  @impl true
  def handle_event("validate", %{"event_proposal" => proposal_params}, socket) do
    changeset =
      socket.assigns.proposal
      |> Events.change_proposal(proposal_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"event_proposal" => proposal_params}, socket) do
    # Handle video upload if present
    proposal_params = handle_video_upload(socket, proposal_params)

    case Events.create_proposal(socket.assigns.current_scope, proposal_params) do
      {:ok, _proposal} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           gettext("Event proposal submitted successfully! An admin will review it shortly.")
         )
         |> push_navigate(to: ~p"/events")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("cancel-video-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :video, ref)}
  end

  @impl true
  def handle_event("cancel-invitation-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :invitation_materials, ref)}
  end

  defp handle_video_upload(socket, proposal_params) do
    video_type = Map.get(proposal_params, "presentation_video_type")

    if video_type == "r2" && socket.assigns.uploads.video.entries != [] do
      # Generate a temporary slug for the video path
      title = Map.get(proposal_params, "title", "event")
      temp_slug = slugify(title)

      uploaded_videos =
        consume_uploaded_entries(socket, :video, fn %{path: path}, entry ->
          key = generate_video_key(temp_slug, entry.client_name)
          content_type = entry.client_type || "video/mp4"

          case R2Storage.upload(path, key, content_type: content_type) do
            {:ok, ^key} -> {:ok, key}
            {:error, reason} -> {:postpone, {:error, reason}}
          end
        end)

      case uploaded_videos do
        [key | _] when is_binary(key) ->
          Map.put(proposal_params, "presentation_video_url", key)

        _ ->
          proposal_params
      end
    else
      proposal_params
    end
  end

  defp generate_video_key(slug, filename) do
    uuid = Ecto.UUID.generate() |> String.slice(0, 8)
    sanitized_filename = sanitize_filename(filename)
    "Events/#{slug}/videos/#{uuid}-#{sanitized_filename}"
  end

  defp sanitize_filename(filename) do
    filename
    |> String.replace(~r/[^a-zA-Z0-9._-]/, "_")
    |> String.slice(0, 200)
  end

  defp error_to_string(:too_large), do: gettext("File is too large. Maximum size is 500MB.")

  defp error_to_string(:not_accepted),
    do: gettext("Invalid file type. Please upload MP4, WebM, or MOV.")

  defp error_to_string(:too_many_files), do: gettext("Only one video file can be uploaded.")
  defp error_to_string(err), do: inspect(err)

  defp invitation_error_to_string(:too_large),
    do: gettext("File is too large. Maximum size is 10MB.")

  defp invitation_error_to_string(:not_accepted),
    do: gettext("Invalid file type. Please upload JPG, PNG, or PDF.")

  defp invitation_error_to_string(:too_many_files),
    do: gettext("Maximum 10 files can be uploaded.")

  defp invitation_error_to_string(err), do: inspect(err)

  defp slugify(title) when is_binary(title) do
    slug =
      title
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9\s-]/, "")
      |> String.replace(~r/\s+/, "-")
      |> String.trim("-")

    if slug == "", do: "event-#{System.system_time(:second)}", else: slug
  end

  defp slugify(_), do: "event-#{System.system_time(:second)}"

  @impl true
  def render(assigns) do
    ~H"""
    <.page_container>
      <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <%!-- Back Button --%>
        <Layouts.events_nav current_page={:propose} />

        <%!-- Form --%>
        <.card size="lg">
          <div class="mb-4 sm:mb-6">
            <h1 class="text-2xl sm:text-3xl font-bold text-base-content mb-2">
              {gettext("Propose a New Event")}
            </h1>
            <p class="text-sm sm:text-base text-base-content/60">
              {gettext("Suggest an event for the community. An admin will review and approve it.")}
            </p>
          </div>

          <.form for={@form} id="proposal-form" phx-change="validate" phx-submit="save">
            <div class="space-y-6">
              <div>
                <.input
                  field={@form[:title]}
                  type="text"
                  label={gettext("Event Title")}
                  placeholder={gettext("e.g., Summer Meditation Retreat 2024")}
                  required
                />
              </div>

              <div>
                <.input
                  field={@form[:description]}
                  type="textarea"
                  label={gettext("Description")}
                  placeholder={
                    gettext("Describe the event, its purpose, and what participants can expect...")
                  }
                  rows="6"
                />
              </div>

              <% is_online = Ecto.Changeset.get_field(@form.source, :is_online) || false %>

              <div class="flex items-center gap-2 pb-2">
                <.input
                  field={@form[:is_online]}
                  type="checkbox"
                  label={gettext("This is an Online Event")}
                />
              </div>

              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <.input
                    field={@form[:event_date]}
                    type="date"
                    label={gettext("Event Date")}
                    required
                  />
                </div>
                <div>
                  <.input
                    field={@form[:start_time]}
                    type="time"
                    label={gettext("Start Time")}
                    required
                  />
                </div>
              </div>

              <%= if is_online do %>
                <div class="bg-base-200/50 border border-base-content/10 rounded-lg p-4">
                  <p class="text-sm text-base-content/70 mb-3">
                    {gettext("Provide at least one: a YouTube link OR a meeting platform link")}
                  </p>
                  <div class="space-y-4">
                    <div>
                      <.input
                        field={@form[:online_url]}
                        type="text"
                        label={gettext("Online Link (YouTube)")}
                        placeholder="https://youtube.com/..."
                      />
                    </div>

                    <div>
                      <.input
                        field={@form[:meeting_platform_link]}
                        type="text"
                        label={gettext("Meeting Platform Link")}
                        placeholder={
                          gettext("https://teams.microsoft.com/... or https://zoom.us/...")
                        }
                      />
                      <p class="mt-1 text-xs text-base-content/60">
                        {gettext(
                          "Enter the link for participants to join the meeting (Teams, Zoom, Google Meet, etc.)"
                        )}
                      </p>
                    </div>
                  </div>
                </div>
              <% else %>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <.input
                      field={@form[:budget_type]}
                      type="select"
                      label={gettext("Budget Type")}
                      options={[
                        {gettext("Donations"), "open_for_donations"},
                        {gettext("Fixed Budget"), "fixed_budget"}
                      ]}
                      required
                    />
                  </div>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <.input
                      field={@form[:city]}
                      type="text"
                      label={gettext("City")}
                      placeholder={gettext("e.g., Rome")}
                      required
                    />
                  </div>
                  <div>
                    <.input
                      field={@form[:country]}
                      type="text"
                      label={gettext("Country")}
                      placeholder={gettext("e.g., Italy")}
                      required
                    />
                  </div>
                </div>
              <% end %>

              <%!-- Presentation Video Section --%>
              <% video_type = Ecto.Changeset.get_field(@form.source, :presentation_video_type) %>
              <div class="border border-base-content/20 rounded-lg p-4">
                <h3 class="text-sm font-medium text-base-content mb-3">
                  {gettext("Presentation Video")}
                  <span class="text-base-content/50 text-xs ml-1">({gettext("Optional")})</span>
                </h3>

                <div class="space-y-4">
                  <div>
                    <.input
                      field={@form[:presentation_video_type]}
                      type="select"
                      label={gettext("Video Source")}
                      options={[
                        {gettext("None"), ""},
                        {gettext("YouTube"), "youtube"},
                        {gettext("Upload Video"), "r2"}
                      ]}
                      prompt={gettext("Select video source")}
                    />
                  </div>

                  <%= if video_type == "youtube" do %>
                    <div>
                      <.input
                        field={@form[:presentation_video_url]}
                        type="text"
                        label={gettext("YouTube Video URL")}
                        placeholder="https://www.youtube.com/watch?v=..."
                      />
                      <p class="mt-1 text-xs text-base-content/60">
                        {gettext(
                          "Enter a valid YouTube video URL (youtube.com/watch, youtu.be, or youtube.com/embed)"
                        )}
                      </p>
                    </div>
                  <% end %>

                  <%= if video_type == "r2" do %>
                    <div>
                      <label class="block text-sm font-medium text-base-content/80 mb-2">
                        {gettext("Upload Video File")}
                      </label>
                      <div
                        id="video-upload-area"
                        class="border-2 border-dashed border-base-content/30 rounded-lg p-6 text-center bg-base-100 hover:bg-base-200 transition-colors"
                        phx-drop-target={@uploads.video.ref}
                      >
                        <.live_file_input upload={@uploads.video} class="hidden" />
                        <label for={@uploads.video.ref} class="cursor-pointer">
                          <.icon
                            name="hero-video-camera"
                            class="w-12 h-12 mx-auto text-base-content/40"
                          />
                          <p class="mt-2 text-sm text-base-content/80">
                            {gettext("Click to upload or drag and drop")}
                          </p>
                          <p class="text-xs text-base-content/60">
                            {gettext("MP4, WebM, MOV - Max 500MB")}
                          </p>
                        </label>
                      </div>

                      <%= for entry <- @uploads.video.entries do %>
                        <div class="mt-4 bg-base-100 p-4 rounded-lg">
                          <div class="flex items-start justify-between mb-3">
                            <div class="flex-1">
                              <p class="text-sm font-medium text-base-content">{entry.client_name}</p>
                              <p class="text-xs text-base-content/60 mt-1">
                                {format_file_size(entry.client_size)}
                              </p>
                            </div>
                            <button
                              type="button"
                              phx-click="cancel-video-upload"
                              phx-value-ref={entry.ref}
                              class="text-error hover:text-error/80 ml-4 focus:outline-none focus:ring-2 focus:ring-error rounded"
                            >
                              <.icon name="hero-x-mark" class="w-5 h-5" />
                            </button>
                          </div>

                          <%!-- Upload progress --%>
                          <div class="mt-3">
                            <div class="w-full bg-base-300 rounded-full h-2">
                              <div
                                class="bg-warning h-2 rounded-full transition-all duration-300"
                                style={"width: #{entry.progress}%"}
                              >
                              </div>
                            </div>
                            <p class="text-xs text-base-content/60 mt-1">{entry.progress}%</p>
                          </div>

                          <%= for err <- upload_errors(@uploads.video, entry) do %>
                            <p class="mt-2 text-xs text-error">{error_to_string(err)}</p>
                          <% end %>
                        </div>
                      <% end %>

                      <%= for err <- upload_errors(@uploads.video) do %>
                        <p class="mt-2 text-xs text-error">{error_to_string(err)}</p>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              </div>

              <%!-- Invitation Materials Section --%>
              <div class="border border-base-content/20 rounded-lg p-4">
                <h3 class="text-sm font-medium text-base-content mb-3">
                  {gettext("Invitation Materials")}
                  <span class="text-base-content/50 text-xs ml-1">({gettext("Optional")})</span>
                </h3>
                <p class="text-xs text-base-content/60 mb-4">
                  {gettext("Upload photos or PDF files to showcase your event invitation")}
                </p>

                <div
                  id="invitation-upload-area"
                  class="border-2 border-dashed border-base-content/30 rounded-lg p-6 text-center bg-base-100 hover:bg-base-200 transition-colors"
                  phx-drop-target={@uploads.invitation_materials.ref}
                >
                  <.live_file_input upload={@uploads.invitation_materials} class="hidden" />
                  <label for={@uploads.invitation_materials.ref} class="cursor-pointer">
                    <.icon name="hero-photo" class="w-12 h-12 mx-auto text-base-content/40" />
                    <p class="mt-2 text-sm text-base-content/80">
                      {gettext("Click to upload or drag and drop")}
                    </p>
                    <p class="text-xs text-base-content/60">
                      {gettext("JPG, PNG, PDF - Max 10MB each (up to 10 files)")}
                    </p>
                  </label>
                </div>

                <%= for entry <- @uploads.invitation_materials.entries do %>
                  <div class="mt-4 bg-base-100 p-4 rounded-lg border border-base-content/10">
                    <div class="flex items-start justify-between mb-3">
                      <div class="flex items-center gap-3 flex-1">
                        <%= if String.ends_with?(String.downcase(entry.client_name), ".pdf") do %>
                          <.icon name="hero-document" class="w-8 h-8 text-error/70" />
                        <% else %>
                          <.icon name="hero-photo" class="w-8 h-8 text-primary/70" />
                        <% end %>
                        <div>
                          <p class="text-sm font-medium text-base-content">{entry.client_name}</p>
                          <p class="text-xs text-base-content/60 mt-1">
                            {format_file_size(entry.client_size)}
                          </p>
                        </div>
                      </div>
                      <button
                        type="button"
                        phx-click="cancel-invitation-upload"
                        phx-value-ref={entry.ref}
                        class="text-error hover:text-error/80 ml-4 focus:outline-none focus:ring-2 focus:ring-error rounded"
                      >
                        <.icon name="hero-x-mark" class="w-5 h-5" />
                      </button>
                    </div>

                    <%!-- Upload progress --%>
                    <div class="mt-3">
                      <div class="w-full bg-base-300 rounded-full h-2">
                        <div
                          class="bg-success h-2 rounded-full transition-all duration-300"
                          style={"width: #{entry.progress}%"}
                        >
                        </div>
                      </div>
                      <p class="text-xs text-base-content/60 mt-1">{entry.progress}%</p>
                    </div>

                    <%= for err <- upload_errors(@uploads.invitation_materials, entry) do %>
                      <p class="mt-2 text-xs text-error">{invitation_error_to_string(err)}</p>
                    <% end %>
                  </div>
                <% end %>

                <%= for err <- upload_errors(@uploads.invitation_materials) do %>
                  <p class="mt-2 text-xs text-error">{invitation_error_to_string(err)}</p>
                <% end %>
              </div>

              <div class="bg-info/10 border border-info/20 rounded-lg p-4">
                <div class="flex items-start gap-3">
                  <.icon name="hero-information-circle" class="w-5 h-5 text-info mt-0.5" />
                  <div class="text-sm text-base-content/70">
                    <p class="font-medium text-base-content mb-1">{gettext("What happens next?")}</p>
                    <ul class="list-disc list-inside space-y-1">
                      <li>{gettext("Your proposal will be reviewed by an admin")}</li>
                      <li>{gettext("If approved, you'll be able to add full event details")}</li>
                      <li>{gettext("You can manage team members, transportation, and more")}</li>
                    </ul>
                  </div>
                </div>
              </div>

              <div class="flex flex-col sm:flex-row gap-3 sm:gap-4 pt-4">
                <.primary_button type="submit" class="w-full sm:w-auto">
                  {gettext("Submit Proposal")}
                </.primary_button>
                <.secondary_button navigate="/events" class="w-full sm:w-auto">
                  {gettext("Cancel")}
                </.secondary_button>
              </div>
            </div>
          </.form>
        </.card>
      </div>
    </.page_container>
    """
  end
end

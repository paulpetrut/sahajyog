defmodule SahajyogWeb.Admin.WeeklyScheduleLive do
  @moduledoc """
  LiveView for managing weekly video schedules for Advanced Topics and Excerpts categories.
  Allows administrators to assign videos to specific weeks and view the schedule calendar.
  """
  use SahajyogWeb, :live_view

  import SahajyogWeb.AdminNav

  alias Sahajyog.Content

  @schedulable_categories ["Advanced Topics", "Excerpts"]

  @impl true
  def mount(_params, _session, socket) do
    {current_year, current_week} = Content.current_iso_week()

    {:ok,
     socket
     |> assign(:page_title, gettext("Weekly Schedule"))
     |> assign(:current_year, current_year)
     |> assign(:current_week, current_week)
     |> assign(:selected_year, current_year)
     |> assign(:selected_week, current_week)
     |> assign(:selected_category, "Advanced Topics")
     |> assign(:schedulable_categories, @schedulable_categories)
     |> assign(:show_assignment_modal, false)
     |> assign(:available_videos, [])
     |> assign(:selected_video_ids, MapSet.new())
     |> load_schedule_data()}
  end

  @impl true
  def handle_event("select_week", %{"year" => year, "week" => week}, socket) do
    year = String.to_integer(year)
    week = String.to_integer(week)

    {:noreply,
     socket
     |> assign(:selected_year, year)
     |> assign(:selected_week, week)
     |> load_schedule_data()}
  end

  def handle_event("change_category", %{"category" => category}, socket) do
    {:noreply,
     socket
     |> assign(:selected_category, category)
     |> load_schedule_data()}
  end

  def handle_event("prev_week", _params, socket) do
    {year, week} = prev_week(socket.assigns.selected_year, socket.assigns.selected_week)

    {:noreply,
     socket
     |> assign(:selected_year, year)
     |> assign(:selected_week, week)
     |> load_schedule_data()}
  end

  def handle_event("next_week", _params, socket) do
    {year, week} = next_week(socket.assigns.selected_year, socket.assigns.selected_week)

    {:noreply,
     socket
     |> assign(:selected_year, year)
     |> assign(:selected_week, week)
     |> load_schedule_data()}
  end

  def handle_event("open_assignment_modal", _params, socket) do
    category = socket.assigns.selected_category
    year = socket.assigns.selected_year
    week = socket.assigns.selected_week

    # Get all videos in the category
    available_videos = Content.list_videos_by_category(category)

    # Get currently assigned video IDs for this week
    current_assignments = Content.list_weekly_assignments(year, week, category)
    assigned_ids = MapSet.new(Enum.map(current_assignments, & &1.video_id))

    {:noreply,
     socket
     |> assign(:show_assignment_modal, true)
     |> assign(:available_videos, available_videos)
     |> assign(:selected_video_ids, assigned_ids)}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_assignment_modal, false)
     |> assign(:available_videos, [])
     |> assign(:selected_video_ids, MapSet.new())}
  end

  def handle_event("toggle_video", %{"id" => id}, socket) do
    video_id = String.to_integer(id)
    selected = socket.assigns.selected_video_ids

    new_selected =
      if MapSet.member?(selected, video_id) do
        MapSet.delete(selected, video_id)
      else
        MapSet.put(selected, video_id)
      end

    {:noreply, assign(socket, :selected_video_ids, new_selected)}
  end

  def handle_event("save_assignments", _params, socket) do
    year = socket.assigns.selected_year
    week = socket.assigns.selected_week
    category = socket.assigns.selected_category
    video_ids = MapSet.to_list(socket.assigns.selected_video_ids)

    # First, remove all existing assignments for this week/category
    current_assignments = Content.list_weekly_assignments(year, week, category)

    Enum.each(current_assignments, fn assignment ->
      Content.remove_video_from_week(assignment.video_id, year, week)
    end)

    # Then add the new assignments
    case Content.assign_videos_to_week(video_ids, year, week) do
      {:ok, _assignments} ->
        {:noreply,
         socket
         |> assign(:show_assignment_modal, false)
         |> assign(:available_videos, [])
         |> assign(:selected_video_ids, MapSet.new())
         |> load_schedule_data()
         |> put_flash(:info, gettext("Videos assigned to week successfully"))}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to assign videos"))}
    end
  end

  def handle_event("remove_video", %{"id" => id}, socket) do
    video_id = String.to_integer(id)
    year = socket.assigns.selected_year
    week = socket.assigns.selected_week

    {:ok, _} = Content.remove_video_from_week(video_id, year, week)

    {:noreply,
     socket
     |> load_schedule_data()
     |> put_flash(:info, gettext("Video removed from week"))}
  end

  # Private functions

  defp load_schedule_data(socket) do
    year = socket.assigns.selected_year
    week = socket.assigns.selected_week
    category = socket.assigns.selected_category

    assignments = Content.list_weekly_assignments(year, week, category)
    week_dates = week_date_range(year, week)

    socket
    |> assign(:assignments, assignments)
    |> assign(:week_dates, week_dates)
  end

  defp prev_week(year, 1) do
    # Go to last week of previous year
    prev_year = year - 1
    last_week = weeks_in_year(prev_year)
    {prev_year, last_week}
  end

  defp prev_week(year, week), do: {year, week - 1}

  defp next_week(year, week) do
    max_weeks = weeks_in_year(year)

    if week >= max_weeks do
      {year + 1, 1}
    else
      {year, week + 1}
    end
  end

  defp weeks_in_year(year) do
    # ISO week calculation - most years have 52 weeks, some have 53
    dec_28 = Date.new!(year, 12, 28)
    {_year, week} = :calendar.iso_week_number(Date.to_erl(dec_28))
    week
  end

  defp week_date_range(year, week) do
    # Find the Monday of the given ISO week
    jan_4 = Date.new!(year, 1, 4)
    jan_4_weekday = Date.day_of_week(jan_4)
    monday_of_week_1 = Date.add(jan_4, 1 - jan_4_weekday)
    monday = Date.add(monday_of_week_1, (week - 1) * 7)
    sunday = Date.add(monday, 6)
    {monday, sunday}
  end

  defp format_date(date) do
    Calendar.strftime(date, "%b %d")
  end

  defp is_current_week?(year, week, current_year, current_week) do
    year == current_year and week == current_week
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_container>
      <.admin_nav current_page={:weekly_schedule} />

      <div class="max-w-7xl mx-auto px-4 py-8">
        <.page_header title={gettext("Weekly Video Schedule")}>
          <:subtitle>
            {gettext("Assign videos to specific weeks for Advanced Topics and Excerpts")}
          </:subtitle>
        </.page_header>

        <%!-- Category Filter --%>
        <div class="mb-6">
          <div class="flex flex-wrap gap-2">
            <button
              :for={category <- @schedulable_categories}
              phx-click="change_category"
              phx-value-category={category}
              class={[
                "px-4 py-2 rounded-lg font-medium transition-all focus:outline-none focus:ring-2 focus:ring-primary",
                if(@selected_category == category,
                  do: "bg-primary text-primary-content",
                  else: "bg-base-200 text-base-content hover:bg-base-300"
                )
              ]}
            >
              {category}
            </button>
          </div>
        </div>

        <%!-- Week Navigation --%>
        <.card class="mb-6">
          <div class="flex items-center justify-between">
            <button
              phx-click="prev_week"
              class="p-2 rounded-lg hover:bg-base-200 transition-colors focus:outline-none focus:ring-2 focus:ring-primary"
            >
              <.icon name="hero-chevron-left" class="w-6 h-6" />
            </button>

            <div class="text-center">
              <div class="flex items-center gap-2 justify-center">
                <h2 class="text-2xl font-bold text-base-content">
                  {gettext("Week %{week}, %{year}", week: @selected_week, year: @selected_year)}
                </h2>
                <span
                  :if={is_current_week?(@selected_year, @selected_week, @current_year, @current_week)}
                  class="px-2 py-1 bg-success/20 text-success text-xs font-semibold rounded"
                >
                  {gettext("Current Week")}
                </span>
              </div>
              <p class="text-base-content/60 mt-1">
                {format_date(elem(@week_dates, 0))} - {format_date(elem(@week_dates, 1))}
              </p>
            </div>

            <button
              phx-click="next_week"
              class="p-2 rounded-lg hover:bg-base-200 transition-colors focus:outline-none focus:ring-2 focus:ring-primary"
            >
              <.icon name="hero-chevron-right" class="w-6 h-6" />
            </button>
          </div>
        </.card>

        <%!-- Assigned Videos Section --%>
        <.card size="lg">
          <div class="flex items-center justify-between mb-6">
            <div>
              <h3 class="text-xl font-bold text-base-content">
                {gettext("Assigned Videos")}
              </h3>
              <p class="text-base-content/60 text-sm mt-1">
                {gettext("%{count} video(s) assigned to this week",
                  count: length(@assignments)
                )}
              </p>
            </div>
            <.primary_button phx-click="open_assignment_modal" icon="hero-plus">
              {gettext("Assign Videos")}
            </.primary_button>
          </div>

          <%!-- Assigned Videos List --%>
          <div :if={@assignments != []} class="space-y-3">
            <div
              :for={assignment <- @assignments}
              class="flex items-center gap-4 p-4 bg-base-100 rounded-lg border border-base-content/10 hover:border-primary/30 transition-colors"
            >
              <div :if={assignment.video.thumbnail_url} class="flex-shrink-0">
                <img
                  src={assignment.video.thumbnail_url}
                  alt={assignment.video.title}
                  class="w-24 h-14 object-cover rounded"
                />
              </div>
              <div
                :if={!assignment.video.thumbnail_url}
                class="flex-shrink-0 w-24 h-14 bg-base-200 rounded flex items-center justify-center"
              >
                <.icon name="hero-video-camera" class="w-8 h-8 text-base-content/30" />
              </div>

              <div class="flex-1 min-w-0">
                <h4 class="font-medium text-base-content truncate">
                  {assignment.video.title}
                </h4>
                <p :if={assignment.video.duration} class="text-sm text-base-content/60">
                  {assignment.video.duration}
                </p>
              </div>

              <button
                phx-click="remove_video"
                phx-value-id={assignment.video_id}
                data-confirm={gettext("Remove this video from the week?")}
                class="p-2 text-error/70 hover:text-error hover:bg-error/10 rounded-lg transition-colors focus:outline-none focus:ring-2 focus:ring-error/50"
                title={gettext("Remove from week")}
              >
                <.icon name="hero-x-mark" class="w-5 h-5" />
              </button>
            </div>
          </div>

          <%!-- Empty State --%>
          <.empty_state
            :if={@assignments == []}
            icon="hero-calendar-days"
            title={gettext("No videos assigned")}
            description={
              gettext("Click 'Assign Videos' to add %{category} videos to this week",
                category: @selected_category
              )
            }
          />
        </.card>
      </div>

      <%!-- Assignment Modal --%>
      <.modal
        :if={@show_assignment_modal}
        id="assignment-modal"
        on_close="close_modal"
        size="lg"
      >
        <:title>{gettext("Assign Videos to Week %{week}", week: @selected_week)}</:title>

        <div class="space-y-4">
          <p class="text-base-content/70">
            {gettext("Select videos from %{category} to assign to this week:",
              category: @selected_category
            )}
          </p>

          <div :if={@available_videos != []} class="space-y-2 max-h-96 overflow-y-auto">
            <button
              :for={video <- @available_videos}
              type="button"
              phx-click="toggle_video"
              phx-value-id={video.id}
              class={[
                "w-full flex items-center gap-3 p-3 rounded-lg border transition-all text-left",
                "focus:outline-none focus:ring-2 focus:ring-primary",
                if(MapSet.member?(@selected_video_ids, video.id),
                  do: "border-primary bg-primary/10",
                  else: "border-base-content/10 hover:border-primary/30 bg-base-100"
                )
              ]}
            >
              <div class={[
                "flex-shrink-0 w-5 h-5 rounded border-2 flex items-center justify-center transition-colors",
                if(MapSet.member?(@selected_video_ids, video.id),
                  do: "border-primary bg-primary",
                  else: "border-base-content/30"
                )
              ]}>
                <.icon
                  :if={MapSet.member?(@selected_video_ids, video.id)}
                  name="hero-check"
                  class="w-3 h-3 text-primary-content"
                />
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
                <p :if={video.duration} class="text-xs text-base-content/60">
                  {video.duration}
                </p>
              </div>
            </button>
          </div>

          <.empty_state
            :if={@available_videos == []}
            icon="hero-video-camera"
            title={gettext("No videos available")}
            description={
              gettext("Add videos to the %{category} category first",
                category: @selected_category
              )
            }
          />
        </div>

        <:footer>
          <.secondary_button phx-click="close_modal">
            {gettext("Cancel")}
          </.secondary_button>
          <.primary_button phx-click="save_assignments">
            {gettext("Save Assignments")}
          </.primary_button>
        </:footer>
      </.modal>
    </.page_container>
    """
  end
end

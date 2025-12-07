defmodule SahajyogWeb.EventShowLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Events
  alias Sahajyog.Events.{EventCarpool, EventNotifier}
  alias Phoenix.LiveView.JS
  alias Timex

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    event = Events.get_event_by_slug!(slug)

    if connected?(socket) do
      Events.subscribe(event.id)
    end

    can_edit = Events.can_edit_event?(socket.assigns.current_scope, event)
    financial = Events.financial_summary(event.id)

    attendance =
      case Events.get_attendance(event.id, socket.assigns.current_scope.user.id) do
        %{status: "attending"} = attendance -> attendance
        _ -> nil
      end

    # Check if user has a confirmed ride
    confirmed_ride =
      Events.get_user_confirmed_carpool(event.id, socket.assigns.current_scope.user.id)

    # Check if user is a driver
    my_carpool =
      Enum.find(event.carpools, fn c ->
        c.driver_user_id == socket.assigns.current_scope.user.id
      end)

    # Show requests logic: default list all, but we might filter later
    requests = Events.list_ride_requests(event.id)

    # Online Event Logic
    {time_remaining, is_live} = calculate_time_remaining(event)
    is_ended = is_event_ended?(event)

    if connected?(socket) && event.online_url && !is_live && !is_ended do
      Process.send_after(self(), :tick, 1000)
    end

    # Check profile completeness for editors
    profile_incomplete =
      can_edit && !Sahajyog.Accounts.User.profile_complete?(socket.assigns.current_scope.user)

    # Determine if contact button should be shown
    # Hide if the current user is the ONLY recipient (Owner + Team)
    show_contact_button =
      if current_user = socket.assigns.current_scope.user do
        team_emails =
          event.team_members
          |> Enum.filter(&(&1.status == "accepted"))
          |> Enum.map(& &1.user.email)

        recipients = [event.user.email | team_emails] |> Enum.uniq()
        recipients != [current_user.email]
      else
        true
      end

    # Check for pending invitation
    pending_invitation =
      if socket.assigns.current_scope.user do
        Enum.find(event.team_members, fn m ->
          m.user_id == socket.assigns.current_scope.user.id and m.status == "pending"
        end)
      else
        nil
      end

    # Fetch participant count
    participant_count = Events.count_attendees(event.id)

    # Presence Logic for Online Events
    if connected?(socket) && event.is_online do
      topic = "event_presence:#{event.id}"
      SahajyogWeb.Endpoint.subscribe(topic)

      presence_meta = %{
        online_at: inspect(System.system_time(:second)),
        user_id: socket.assigns.current_scope.user.id,
        email: socket.assigns.current_scope.user.email,
        first_name: socket.assigns.current_scope.user.first_name,
        last_name: socket.assigns.current_scope.user.last_name,
        # Use avatar URL if available, else derive initials
        avatar: nil
      }

      {:ok, _} =
        SahajyogWeb.Presence.track(
          self(),
          topic,
          socket.assigns.current_scope.user.id,
          presence_meta
        )
    end

    {:ok,
     socket
     |> assign(:page_title, event.title)
     |> assign(:event, event)
     |> assign(:can_edit, can_edit)
     |> assign(:profile_incomplete, profile_incomplete)
     |> assign(:pending_invitation, pending_invitation)
     |> assign(:financial, financial)
     |> assign(:attendance, attendance)
     |> assign(:ride_requests, requests)
     |> assign(:participant_count, participant_count)
     |> assign(:confirmed_ride, confirmed_ride)
     |> assign(:my_carpool, my_carpool)
     |> assign(:show_carpool_form, false)
     |> assign(:carpool_form, nil)
     |> assign(:show_request_form, false)
     |> assign(:request_form, nil)
     |> assign(:time_remaining, time_remaining)
     |> assign(:is_live, is_live)
     |> assign(:is_ended, is_ended)
     |> assign(:show_contact_modal, false)
     |> assign(:show_contact_button, show_contact_button)
     |> assign(:focus_mode, false)
     # Will be populated by handle_info
     |> assign(:connected_users, [])
     |> handle_presence_state(event)}
  end

  defp handle_presence_state(socket, event) do
    if event.is_online do
      topic = "event_presence:#{event.id}"
      # Initial state
      presences = SahajyogWeb.Presence.list(topic)

      users =
        presences
        |> Enum.map(fn {_user_id, entry} -> List.first(entry.metas) end)

      assign(socket, :connected_users, users)
    else
      socket
    end
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: _diff}, socket) do
    if socket.assigns.event.is_online do
      topic = "event_presence:#{socket.assigns.event.id}"
      presences = SahajyogWeb.Presence.list(topic)

      users =
        presences
        |> Enum.map(fn {_user_id, entry} -> List.first(entry.metas) end)

      {:noreply, assign(socket, :connected_users, users)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:tick, socket) do
    if socket.assigns.event.online_url && !socket.assigns.is_live do
      {time_remaining, is_live} = calculate_time_remaining(socket.assigns.event)

      if !is_live do
        Process.send_after(self(), :tick, 1000)
      end

      {:noreply, assign(socket, time_remaining: time_remaining, is_live: is_live)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:event_updated, event_id}, socket) do
    if socket.assigns.event.id == event_id do
      event = Events.get_event_by_slug!(socket.assigns.event.slug)
      requests = Events.list_ride_requests(event.id)

      confirmed_ride =
        Events.get_user_confirmed_carpool(event.id, socket.assigns.current_scope.user.id)

      my_carpool =
        Enum.find(event.carpools, fn c ->
          c.driver_user_id == socket.assigns.current_scope.user.id
        end)

      # Recalculate live status on update
      {time_remaining, is_live} = calculate_time_remaining(event)
      is_ended = is_event_ended?(event)

      # Re-check pending invitation
      pending_invitation =
        if socket.assigns.current_scope.user do
          Enum.find(event.team_members, fn m ->
            m.user_id == socket.assigns.current_scope.user.id and m.status == "pending"
          end)
        else
          nil
        end

      {:noreply,
       socket
       |> assign(:event, event)
       |> assign(:pending_invitation, pending_invitation)
       |> assign(:ride_requests, requests)
       |> assign(:confirmed_ride, confirmed_ride)
       |> assign(:my_carpool, my_carpool)
       |> assign(:time_remaining, time_remaining)
       |> assign(:is_live, is_live)
       |> assign(:is_ended, is_ended)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("accept_invitation", _, socket) do
    user = socket.assigns.current_scope.user

    if !Sahajyog.Accounts.User.profile_complete?(user) do
      encoded_return = URI.encode_www_form(~p"/events/#{socket.assigns.event.slug}")

      {:noreply,
       socket
       |> put_flash(
         :error,
         gettext(
           "Please complete your profile details (First Name, Last Name, Phone Number) before accepting this invitation."
         )
       )
       |> push_navigate(to: ~p"/users/settings?return_to=#{encoded_return}")}
    else
      case socket.assigns.pending_invitation do
        nil ->
          {:noreply, socket}

        invitation ->
          {:ok, _} = Events.accept_team_invitation(invitation)

          {:noreply,
           socket
           # Reload event to update permissions/view
           |> push_navigate(to: ~p"/events/#{socket.assigns.event.slug}")
           |> put_flash(:info, gettext("Invitation accepted! You are now a co-owner."))}
      end
    end
  end

  @impl true
  def handle_event("reject_invitation", _, socket) do
    case socket.assigns.pending_invitation do
      nil ->
        {:noreply, socket}

      invitation ->
        {:ok, _} = Events.reject_team_invitation(invitation)

        {:noreply,
         socket
         |> assign(:pending_invitation, nil)
         |> put_flash(:info, gettext("Invitation declined."))}
    end
  end

  @impl true
  def handle_event("request_carpool", %{"carpool_id" => carpool_id}, socket) do
    case Events.request_carpool_seat(socket.assigns.current_scope, String.to_integer(carpool_id)) do
      {:ok, _request} ->
        event = Events.get_event_by_slug!(socket.assigns.event.slug)

        {:noreply,
         socket
         |> assign(:event, event)
         |> put_flash(
           :info,
           gettext("Carpool seat requested! The driver will review your request.")
         )}

      {:error, _changeset} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           gettext("Could not request seat. You may have already requested this carpool.")
         )}
    end
  end

  @impl true
  def handle_event("accept_request", %{"request_id" => request_id}, socket) do
    request = Events.get_carpool_request!(request_id)
    # Verify user is driver
    if Events.is_carpool_driver?(socket.assigns.current_scope.user, request.carpool_id) do
      {:ok, _} = Events.accept_carpool_request(request)
      event = Events.get_event_by_slug!(socket.assigns.event.slug)

      {:noreply,
       socket
       |> assign(:event, event)
       |> put_flash(:info, gettext("Request accepted"))}
    else
      {:noreply, put_flash(socket, :error, gettext("Unauthorized"))}
    end
  end

  def handle_event("volunteer_task", %{"task_id" => task_id}, socket) do
    case Events.join_task(socket.assigns.current_scope.user, task_id) do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, gettext("You have joined the task!"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Could not join task"))}
    end
  end

  def handle_event("leave_task", %{"task_id" => task_id}, socket) do
    Events.leave_task(socket.assigns.current_scope.user, task_id)
    {:noreply, put_flash(socket, :info, gettext("You have left the task."))}
  end

  @impl true
  def handle_event("reject_request", %{"request_id" => request_id}, socket) do
    request = Events.get_carpool_request!(request_id)
    carpool = Events.get_carpool!(request.carpool_id)

    if carpool.driver_user_id == socket.assigns.current_scope.user.id do
      {:ok, _} = Events.reject_carpool_request(request)

      event = Events.get_event_by_slug!(socket.assigns.event.slug)
      requests = Events.list_ride_requests(event.id)

      {:noreply,
       socket
       |> assign(:event, event)
       |> assign(:ride_requests, requests)
       |> put_flash(:info, gettext("Request rejected."))}
    else
      {:noreply, put_flash(socket, :error, gettext("Unauthorized action."))}
    end
  end

  @impl true
  def handle_event("show_carpool_form", _, socket) do
    carpool = %Sahajyog.Events.EventCarpool{}
    changeset = Events.change_carpool(carpool)

    {:noreply,
     socket
     |> assign(:show_carpool_form, true)
     |> assign(:carpool_form, to_form(changeset))}
  end

  @impl true
  def handle_event("hide_carpool_form", _, socket) do
    {:noreply,
     socket
     |> assign(:show_carpool_form, false)
     |> assign(:carpool_form, nil)}
  end

  @impl true
  def handle_event("validate_carpool", %{"event_carpool" => carpool_params}, socket) do
    changeset =
      %Sahajyog.Events.EventCarpool{}
      |> Events.change_carpool(carpool_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :carpool_form, to_form(changeset))}
  end

  @impl true
  def handle_event("create_carpool", %{"event_carpool" => carpool_params}, socket) do
    case Events.create_carpool(
           socket.assigns.current_scope,
           socket.assigns.event.id,
           carpool_params
         ) do
      {:ok, _carpool} ->
        event = Events.get_event_by_slug!(socket.assigns.event.slug)

        {:noreply,
         socket
         |> assign(:event, event)
         |> assign(:show_carpool_form, false)
         |> assign(:carpool_form, nil)
         |> put_flash(:info, gettext("Carpool offer created successfully!"))}

      {:error, changeset} ->
        {:noreply, assign(socket, :carpool_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("toggle_attendance", _, socket) do
    user_id = socket.assigns.current_scope.user.id
    event_id = socket.assigns.event.id

    if socket.assigns.attendance do
      Events.unsubscribe_from_event(user_id, event_id)
      {:noreply, assign(socket, :attendance, nil)}
    else
      {:ok, attendance} = Events.subscribe_to_event(user_id, event_id)
      {:noreply, assign(socket, :attendance, attendance)}
    end
  end

  @impl true
  def handle_event("show_request_form", _, socket) do
    request = %Sahajyog.Events.EventRideRequest{}
    changeset = Events.change_ride_request(request)

    {:noreply,
     socket
     |> assign(:show_request_form, true)
     |> assign(:request_form, to_form(changeset))}
  end

  @impl true
  def handle_event("hide_request_form", _, socket) do
    {:noreply,
     socket
     |> assign(:show_request_form, false)
     |> assign(:request_form, nil)}
  end

  @impl true
  def handle_event("validate_request", %{"event_ride_request" => request_params}, socket) do
    changeset =
      %Sahajyog.Events.EventRideRequest{}
      |> Events.change_ride_request(request_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :request_form, to_form(changeset))}
  end

  @impl true
  def handle_event("pick_up_passenger", %{"request_id" => request_id}, socket) do
    if socket.assigns.my_carpool do
      case Events.pick_up_passenger(
             socket.assigns.current_scope.user,
             socket.assigns.my_carpool.id,
             request_id
           ) do
        {:ok, :picked_up} ->
          event = Events.get_event_by_slug!(socket.assigns.event.slug)
          # Refresh requests list
          requests = Events.list_ride_requests(event.id)

          {:noreply,
           socket
           |> assign(:event, event)
           |> assign(:ride_requests, requests)
           |> put_flash(:info, gettext("Passenger picked up!"))}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Could not pick up passenger."))}
      end
    else
      {:noreply,
       put_flash(socket, :error, gettext("You must have a carpool to pick up passengers."))}
    end
  end

  @impl true
  def handle_event("create_request", %{"event_ride_request" => request_params}, socket) do
    case Events.create_ride_request(
           socket.assigns.current_scope,
           socket.assigns.event.id,
           request_params
         ) do
      {:ok, _request} ->
        requests = Events.list_ride_requests(socket.assigns.event.id)

        {:noreply,
         socket
         |> assign(:ride_requests, requests)
         |> assign(:show_request_form, false)
         |> assign(:request_form, nil)
         |> put_flash(:info, gettext("Ride request posted successfully!"))}

      {:error, changeset} ->
        {:noreply, assign(socket, :request_form, to_form(changeset))}
    end
  end

  def handle_event("delete_ride_request", %{"request_id" => request_id}, socket) do
    request =
      Events.list_ride_requests_internal(socket.assigns.event.id)
      |> Enum.find(&(&1.id == String.to_integer(request_id)))

    if request && request.passenger_user_id == socket.assigns.current_scope.user.id do
      {:ok, _} = Events.delete_ride_request(request)
      {:noreply, put_flash(socket, :info, gettext("Request deleted."))}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("leave_ride", _params, socket) do
    case Events.leave_carpool(socket.assigns.current_scope.user, socket.assigns.event.id) do
      {:ok, :left} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("You have left the ride."))
         # Optimistic update, but handle_info will fix it too
         |> assign(:confirmed_ride, nil)}

      _ ->
        {:noreply, put_flash(socket, :error, gettext("Could not leave ride."))}
    end
  end

  @impl true
  def handle_event("delete_carpool", %{"carpool_id" => carpool_id}, socket) do
    carpool = Events.get_carpool!(carpool_id)

    if carpool.driver_user_id == socket.assigns.current_scope.user.id do
      case Events.delete_carpool(carpool) do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_flash(:info, gettext("Carpool offer deleted."))
           |> assign(:my_carpool, nil)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Could not delete carpool."))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Unauthorized."))}
    end
  end

  @impl true
  def handle_event("cancel_carpool_request", %{"carpool_id" => carpool_id}, socket) do
    # We need to find the specific pending request for this user on this carpool
    # Since we don't have the request ID easily in the loop without fetching,
    # let's assume valid user interaction and find it backend side or use `leave_carpool` logic which handles "requests" inherently differently?
    # Actually `leave_carpool` handles accepted ones.
    # For pending requests, we can reuse `leave_carpool` logic IF we modify it or just implement a specific helper.
    # Let's just find the request here for simplicity or add a helper in Events.

    # Re-using logic: finding the request by user_id and carpool_id
    carpool = Events.get_carpool!(carpool_id)

    request =
      Enum.find(carpool.requests, fn r ->
        r.passenger_user_id == socket.assigns.current_scope.user.id and r.status == "pending"
      end)

    if request do
      # Rejecting acts as cancelling effectively? Or we should delete.
      {:ok, _} = Events.reject_carpool_request(request)

      # Events.delete_carpool_request is better but we don't have it exposed publically as "delete".
      # Using reject for now or simple delete via Context if I added it?
      # I didn't add delete_carpool_request explicitly.
      # Let's use Repo.delete inside a quick context helper I missed or just do it here? No, context.
      # Actually `reject_carpool_request` logic sets status to rejected. That works perfectly fine to "cancel" it.
      {:noreply, put_flash(socket, :info, gettext("Request cancelled."))}
    else
      {:noreply, put_flash(socket, :error, gettext("Request not found."))}
    end
  end

  def handle_event("toggle_focus_mode", _, socket) do
    {:noreply, assign(socket, :focus_mode, !socket.assigns.focus_mode)}
  end

  def handle_event("open_contact_modal", _, socket) do
    {:noreply, assign(socket, :show_contact_modal, true)}
  end

  def handle_event("close_contact_modal", _, socket) do
    {:noreply, assign(socket, :show_contact_modal, false)}
  end

  def handle_event(
        "send_contact_message",
        %{"sender_name" => name, "sender_email" => email, "message" => message},
        socket
      ) do
    event = socket.assigns.event

    # Collect recipients: Owner + Accepted Team Members
    team_emails =
      event.team_members
      |> Enum.filter(&(&1.status == "accepted"))
      |> Enum.map(& &1.user.email)

    recipients = [event.user.email | team_emails] |> Enum.uniq()

    EventNotifier.deliver_contact_email(recipients, email, name, event.title, message)

    {:noreply,
     socket
     |> assign(:show_contact_modal, false)
     |> put_flash(:info, gettext("Message sent to the organizers."))}
  end

  defp format_date(date), do: Calendar.strftime(date, "%B %d, %Y")

  defp format_time(nil), do: ""
  defp format_time(time), do: Calendar.strftime(time, "%H:%M")

  defp format_event_time_display(%{event_date: date, event_time: time, timezone: timezone}) do
    tz = timezone || "Etc/UTC"
    naive = NaiveDateTime.new!(date, time)

    case Timex.to_datetime(naive, tz) do
      %DateTime{} = dt ->
        Timex.format!(dt, "%I:%M %p", :strftime) <> " " <> (timezone || "")

      _ ->
        format_time(time)
    end
  end

  defp format_event_time_display(_), do: ""

  defp days_until(nil), do: nil
  defp days_until(date), do: Date.diff(date, Date.utc_today())

  defp status_class("draft"), do: "bg-warning/10 text-warning border border-warning/20"
  defp status_class("public"), do: "bg-success/10 text-success border border-success/20"
  defp status_class("cancelled"), do: "bg-error/10 text-error border border-error/20"

  defp status_class(_),
    do: "bg-base-content/10 text-base-content/60 border border-base-content/20"

  defp task_status_class("pending"), do: "bg-base-content/10 text-base-content/60"
  defp task_status_class("in_progress"), do: "bg-info/10 text-info"
  defp task_status_class("completed"), do: "bg-success/10 text-success"
  defp task_status_class(_), do: "bg-base-content/10 text-base-content/60"

  defp carpool_status_color(carpool) do
    remaining = EventCarpool.remaining_seats(carpool)
    total = carpool.available_seats

    cond do
      carpool.status == "full" || remaining == 0 -> "error"
      remaining <= div(total, 3) -> "warning"
      true -> "success"
    end
  end

  defp transport_type_icon("public"), do: "hero-building-office-2"
  defp transport_type_icon("bus"), do: "hero-truck"
  defp transport_type_icon(_), do: "hero-map"

  defp calculate_time_remaining(%{event_date: nil}),
    do: {%{days: 0, hours: 0, minutes: 0, seconds: 0}, false}

  defp calculate_time_remaining(%{event_date: _date, event_time: nil} = event) do
    # Default to midnight if no time
    calculate_time_remaining(%{event | event_time: Time.new!(0, 0, 0)})
  end

  defp calculate_time_remaining(%{event_date: date, event_time: time, timezone: timezone}) do
    # Use stored timezone or default to UTC if missing
    tz = timezone || "Etc/UTC"
    naive = NaiveDateTime.new!(date, time)

    case Timex.to_datetime(naive, tz) do
      %DateTime{} = start_dt ->
        now = Timex.now()
        # diff in seconds
        diff_seconds = Timex.diff(start_dt, now, :seconds)

        if diff_seconds <= 0 do
          # Event started
          {%{days: 0, hours: 0, minutes: 0, seconds: 0}, true}
        else
          days = div(diff_seconds, 86400)
          rem_seconds = rem(diff_seconds, 86400)
          hours = div(rem_seconds, 3600)
          rem_seconds = rem(rem_seconds, 3600)
          minutes = div(rem_seconds, 60)
          seconds = rem(rem_seconds, 60)

          {%{days: days, hours: hours, minutes: minutes, seconds: seconds}, false}
        end

      {:error, _} ->
        # Fallback if invalid date/time/tz
        {%{days: 0, hours: 0, minutes: 0, seconds: 0}, false}
    end
  end

  defp get_video_id(url) do
    regex = ~r/(?:v=|\/)([0-9A-Za-z_-]{11}).*/

    case Regex.run(regex, url) do
      [_, id] -> id
      _ -> ""
    end
  end

  defp is_event_ended?(%{end_date: end_date, end_time: end_time, timezone: timezone})
       when not is_nil(end_date) and not is_nil(end_time) do
    tz = timezone || "Etc/UTC"
    naive = NaiveDateTime.new!(end_date, end_time)

    case Timex.to_datetime(naive, tz) do
      %DateTime{} = end_dt ->
        # 1 means now > end_dt
        Timex.compare(Timex.now(), end_dt) == 1

      _ ->
        false
    end
  end

  defp is_event_ended?(_), do: false

  @impl true
  def render(assigns) do
    ~H"""
    <.page_container>
      <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <%!-- Contact Modal --%>
        <%= if @show_contact_modal do %>
          <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
            <div class="bg-base-100 rounded-xl shadow-xl w-full max-w-lg p-6 animate-in fade-in zoom-in duration-200">
              <h3 class="text-lg font-bold mb-4">{gettext("Contact Organizers")}</h3>

              <form phx-submit="send_contact_message">
                <div class="space-y-4">
                  <div>
                    <label class="label label-text font-medium">{gettext("Your Name")}</label>
                    <input
                      type="text"
                      name="sender_name"
                      class="input input-bordered w-full"
                      value={(@current_scope.user.first_name || "") <> " " <> (@current_scope.user.last_name || "")}
                      required
                    />
                  </div>
                  <div>
                    <label class="label label-text font-medium">{gettext("Your Email")}</label>
                    <input
                      type="email"
                      name="sender_email"
                      class="input input-bordered w-full"
                      value={@current_scope.user.email}
                      required
                    />
                  </div>
                  <div>
                    <label class="label label-text font-medium">{gettext("Message")}</label>
                    <textarea
                      name="message"
                      class="textarea textarea-bordered w-full"
                      rows="4"
                      required
                      placeholder={gettext("How can we help you?")}
                    ></textarea>
                  </div>
                </div>

                <div class="flex justify-end gap-2 mt-6">
                  <button type="button" phx-click="close_contact_modal" class="btn btn-ghost">
                    {gettext("Cancel")}
                  </button>
                  <button type="submit" class="btn btn-primary">{gettext("Send Message")}</button>
                </div>
              </form>
            </div>
          </div>
        <% end %>

        <%!-- Back Button --%>
        <Layouts.events_nav current_page={:show} />

        <%!-- Profile Warning --%>
        <%= if @profile_incomplete do %>
          <.alert
            kind={:error}
            class="mb-6 cursor-pointer"
            phx-click={JS.navigate(~p"/users/settings")}
          >
            <div class="flex items-center justify-between w-full">
              <span>
                {gettext(
                  "Please complete your profile (First Name, Last Name, Phone Number) to manage this event."
                )}
              </span>
              <.icon name="hero-arrow-right" class="w-4 h-4" />
            </div>
          </.alert>
        <% end %>

        <%!-- Pending Invitation Alert --%>
        <%= if @pending_invitation do %>
          <.alert kind={:info} class="mb-6">
            <div class="flex flex-col sm:flex-row items-center justify-between w-full gap-4">
              <div>
                <h3 class="font-bold">{gettext("You have been invited!")}</h3>
                <p class="text-sm">
                  {gettext("You have been invited to be a co-owner of this event.")}
                </p>
              </div>
              <div class="flex gap-2">
                <button
                  phx-click="accept_invitation"
                  class="btn btn-sm btn-primary"
                >
                  {gettext("Accept")}
                </button>
                <button
                  phx-click="reject_invitation"
                  class="btn btn-sm btn-ghost"
                >
                  {gettext("Decline")}
                </button>
              </div>
            </div>
          </.alert>
        <% end %>

        <%!-- Online Event Hero / Countdown --%>
        <%= if @event.online_url do %>
          <.card size="lg" class="mb-6 overflow-hidden relative">
            <div class="absolute inset-0 bg-gradient-to-br from-primary/5 to-secondary/5 -z-10"></div>

            <%!-- Focus Mode Toggle --%>
            <div class="absolute top-4 right-4 z-10 flex items-start gap-2">
              <%!-- Watching Now Badge --%>
              <%= if @is_live do %>
                <div class="relative group flex flex-col items-end">
                  <div class="flex items-center gap-2 px-3 py-1.5 bg-base-100/50 backdrop-blur text-base-content rounded-full text-xs font-bold border border-base-content/10 shadow-lg cursor-help">
                    <span class="w-2 h-2 rounded-full bg-red-500 animate-pulse"></span>
                    {gettext("%{count} Watching Now", count: length(@connected_users))}
                  </div>

                  <%!-- Online Users List --%>
                  <%= if @connected_users != [] do %>
                    <div class="absolute top-full right-0 mt-2 w-48 flex flex-col gap-1 p-2 bg-base-100/90 backdrop-blur rounded-lg border border-base-content/10 shadow-xl max-h-64 overflow-y-auto hidden group-hover:flex transition-all z-20">
                      <p class="text-[10px] uppercase tracking-wider text-base-content/50 font-bold mb-1 px-1">
                        {gettext("Who is here")}
                      </p>
                      <% visible_users = Enum.take(@connected_users, 20) %>
                      <% overflow_count = length(@connected_users) - length(visible_users) %>

                      <%= for user <- visible_users do %>
                        <div class="flex items-center gap-2 px-1 py-1 hover:bg-base-content/5 rounded">
                          <% first_name = user[:first_name]
                          email = user[:email] || "?"

                          initial =
                            if first_name do
                              String.first(first_name)
                            else
                              String.first(email)
                            end

                          display_name =
                            if first_name do
                              "#{first_name} #{user[:last_name] || ""}" |> String.trim()
                            else
                              (email || "Guest") |> String.split("@") |> List.first()
                            end %>
                          <div class="w-5 h-5 rounded-full bg-primary/10 flex items-center justify-center text-[9px] text-primary font-bold shrink-0">
                            {initial}
                          </div>
                          <span class="text-xs text-base-content/90 truncate">
                            {display_name}
                          </span>
                        </div>
                      <% end %>

                      <%= if overflow_count > 0 do %>
                        <div class="px-2 py-1 text-xs text-base-content/50 italic text-center border-t border-base-content/5 mt-1">
                          {gettext("and %{count} more...", count: overflow_count)}
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              <% end %>

              <button
                phx-click="toggle_focus_mode"
                class={[
                  "btn btn-sm btn-ghost bg-base-100/50 backdrop-blur hover:bg-base-100/80 transition-all gap-2",
                  @focus_mode && "text-primary bg-base-100/80"
                ]}
              >
                <%= if @focus_mode do %>
                  <.icon name="hero-arrows-pointing-in" class="w-4 h-4" />
                  <span>{gettext("Exit Focus Mode")}</span>
                <% else %>
                  <.icon name="hero-arrows-pointing-out" class="w-4 h-4" />
                  <span>{gettext("Focus Mode")}</span>
                <% end %>
              </button>
            </div>

            <div class="flex flex-col items-center justify-center text-center p-6 sm:p-10">
              <%= if @is_ended do %>
                <div class="mb-6">
                  <span class="px-3 py-1 bg-neutral/10 text-neutral-content rounded-full text-sm font-medium border border-neutral/20">
                    {gettext("Event Ended")}
                  </span>
                </div>
                <h2 class="text-3xl sm:text-4xl md:text-5xl font-black text-base-content mb-4 tracking-tight">
                  {gettext("This event has ended")}
                </h2>
                <p class="text-base-content/60 max-w-lg text-lg">
                  {gettext("Thank you for your interest. Please check our other events.")}
                </p>
              <% else %>
                <%= if @is_live do %>
                  <div class="w-full max-w-4xl aspect-video rounded-xl overflow-hidden shadow-2xl bg-black relative group">
                    <iframe
                      src={"https://www.youtube.com/embed/#{get_video_id(@event.online_url)}?autoplay=1"}
                      title="Event Live Stream"
                      frameborder="0"
                      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                      allowfullscreen
                      class="w-full h-full"
                    >
                    </iframe>
                  </div>
                <% else %>
                  <div class="mb-6">
                    <span class="px-3 py-1 bg-primary/10 text-primary rounded-full text-sm font-medium border border-primary/20">
                      {gettext("Online Event")}
                    </span>
                  </div>
                  <h2 class="text-3xl sm:text-4xl md:text-5xl font-black text-base-content mb-4 tracking-tight">
                    {gettext("Starting Soon")}
                  </h2>
                  <p class="text-base-content/60 max-w-lg mb-8 text-lg">
                    {gettext(
                      "Join us for the live stream. The video will appear here automatically when the event starts."
                    )}
                  </p>

                  <div class="grid grid-cols-4 gap-4 text-center">
                    <div class="flex flex-col">
                      <span class="text-3xl sm:text-4xl font-bold font-mono text-primary">
                        {@time_remaining.days}
                      </span>
                      <span class="text-xs uppercase tracking-wider text-base-content/50">
                        {gettext("Days")}
                      </span>
                    </div>
                    <div class="flex flex-col">
                      <span class="text-3xl sm:text-4xl font-bold font-mono text-primary">
                        {@time_remaining.hours}
                      </span>
                      <span class="text-xs uppercase tracking-wider text-base-content/50">
                        {gettext("Hours")}
                      </span>
                    </div>
                    <div class="flex flex-col">
                      <span class="text-3xl sm:text-4xl font-bold font-mono text-primary">
                        {@time_remaining.minutes}
                      </span>
                      <span class="text-xs uppercase tracking-wider text-base-content/50">
                        {gettext("Minutes")}
                      </span>
                    </div>
                    <div class="flex flex-col">
                      <span class="text-3xl sm:text-4xl font-bold font-mono text-primary">
                        {@time_remaining.seconds}
                      </span>
                      <span class="text-xs uppercase tracking-wider text-base-content/50">
                        {gettext("Seconds")}
                      </span>
                    </div>
                  </div>
                  <div class="mt-8 text-base-content/50 text-sm">
                    <span
                      id="local-time-hero"
                      phx-hook="LocalTime"
                      data-date={@event.event_date}
                      data-time={@event.event_time}
                      class="invisible"
                    >
                      {format_date(@event.event_date)} • {format_time(@event.event_time)}
                    </span>
                  </div>
                <% end %>
              <% end %>
            </div>
          </.card>
        <% end %>

        <%= unless @focus_mode do %>
          <%!-- Header Card --%>
          <.card size="lg" class="mb-6">
            <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4 mb-4">
              <div class="flex-1">
                <%!-- Status Badge --%>
                <div class="mb-3">
                  <span class={[
                    "px-3 py-1 rounded-full text-sm font-medium",
                    status_class(@event.status)
                  ]}>
                    {@event.status}
                  </span>
                  <%= if @event.event_date && days_until(@event.event_date) do %>
                    <% days = days_until(@event.event_date) %>
                    <%= cond do %>
                      <% days == 0 -> %>
                        <%= if !@is_live do %>
                          <span class="ml-2 px-3 py-1 bg-accent text-accent-content rounded-full text-sm font-bold shadow-lg shadow-accent/20 animate-pulse">
                            {gettext("Today!")}
                          </span>
                        <% else %>
                          <span class="ml-2 px-3 py-1 bg-primary/20 text-primary rounded-full text-sm font-medium">
                            {gettext("Today!")}
                          </span>
                        <% end %>
                      <% days == 1 -> %>
                        <span class="ml-2 px-3 py-1 bg-primary/20 text-primary rounded-full text-sm font-medium">
                          {gettext("Tomorrow")}
                        </span>
                      <% days > 0 and days <= 7 -> %>
                        <span class="ml-2 px-3 py-1 bg-primary/10 text-primary rounded-full text-sm font-medium">
                          {gettext("In %{days} days", days: days)}
                        </span>
                      <% true -> %>
                    <% end %>
                  <% end %>
                </div>

                <h1 class="text-2xl sm:text-3xl lg:text-4xl font-bold text-base-content mb-4">
                  {@event.title}
                </h1>

                <%!-- Quick Info --%>
                <div class="flex flex-wrap gap-4 text-sm text-base-content/70">
                  <%= if @event.event_date do %>
                    <span class="flex items-center gap-2">
                      <.icon name="hero-calendar" class="w-4 h-4" />
                      {format_date(@event.event_date)}
                      <%= if @event.event_time do %>
                        <span class="text-base-content/40">•</span>
                        {format_event_time_display(@event)}
                      <% end %>
                    </span>
                  <% end %>
                  <%= if @event.city || @event.country do %>
                    <span class="flex items-center gap-2">
                      <.icon name="hero-map-pin" class="w-4 h-4" />
                      {[@event.city, @event.country] |> Enum.reject(&is_nil/1) |> Enum.join(", ")}
                    </span>
                  <% end %>
                  <%= if @participant_count > 0 do %>
                    <span class="flex items-center gap-2" title={gettext("Confirmed Attendees")}>
                      <.icon name="hero-users" class="w-4 h-4" />
                      {@participant_count} {gettext("Attending")}
                    </span>
                  <% end %>
                  <%= if @event.estimated_participants do %>
                    <span class="flex items-center gap-2 text-base-content/50">
                      <.icon name="hero-users" class="w-4 h-4" />
                      {gettext("%{count} expected", count: @event.estimated_participants)}
                    </span>
                  <% end %>
                </div>
              </div>

              <%= if @can_edit do %>
                <.primary_button navigate={~p"/events/#{@event.slug}/edit"} icon="hero-pencil-square">
                  {gettext("Edit Event")}
                </.primary_button>
              <% end %>

              <%= if @event.status == "public" do %>
                <button
                  phx-click="toggle_attendance"
                  class={[
                    "px-4 py-2 rounded-lg font-medium transition-colors flex items-center gap-2",
                    if(@attendance,
                      do: "bg-base-200 text-base-content hover:bg-base-300",
                      else: "bg-primary text-primary-content hover:bg-primary/90"
                    )
                  ]}
                >
                  <%= if @attendance do %>
                    <.icon name="hero-check" class="w-5 h-5" />
                    {gettext("Attending")}
                  <% else %>
                    <.icon name="hero-plus" class="w-5 h-5" />
                    {gettext("Attend")}
                  <% end %>
                </button>
              <% end %>
            </div>

            <%= if @attendance do %>
              <div class="mb-4 p-4 bg-success/10 text-success rounded-lg border border-success/20 flex items-center gap-3">
                <.icon name="hero-check-circle" class="w-6 h-6" />
                <div class="flex-1">
                  <p class="font-medium">{gettext("You are attending this event!")}</p>
                  <p class="text-sm opacity-80">
                    {gettext("This event will appear in your")}
                    <.link
                      navigate={~p"/events?filter=my_events"}
                      class="underline hover:text-success-content"
                    >
                    {gettext("'My Events' list")}
                  </.link>.
                  </p>
                </div>
              </div>
            <% end %>

            <%!-- Organizer --%>
            <div class="pt-4 border-t border-base-content/10 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <div class="flex items-center gap-3">
                <.icon name="hero-user" class="w-5 h-5 text-base-content/50" />
                <span class="text-sm text-base-content/60">
                  {gettext("Organized by")}
                  <span class="font-medium text-base-content">{@event.user.email}</span>
                </span>
              </div>
              <%= if @show_contact_button do %>
                <button phx-click="open_contact_modal" class="btn btn-sm btn-outline gap-2">
                  <.icon name="hero-envelope" class="w-4 h-4" />
                  {gettext("Contact Organizer")}
                </button>
              <% end %>
            </div>

            <%!-- Team Members --%>
            <%= if @event.team_members != [] do %>
              <div class="mt-3 flex flex-wrap gap-2">
                <span class="text-sm text-base-content/60">{gettext("Team")}:</span>
                <span
                  :for={member <- Enum.filter(@event.team_members, &(&1.status == "accepted"))}
                  class="px-2 py-1 bg-primary/10 text-primary rounded-full text-xs border border-primary/20"
                >
                  {member.user.email |> String.split("@") |> List.first()}
                </span>
              </div>
            <% end %>
          </.card>

          <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div class="lg:col-span-2 space-y-6">
              <%!-- Description --%>
              <%= if @event.description do %>
                <.card size="lg" class="mb-6">
                  <h2 class="text-xl font-bold text-base-content mb-4 flex items-center gap-2">
                    <.icon name="hero-document-text" class="w-5 h-5" />
                    {gettext("About this Event")}
                  </h2>
                  <div class="prose prose-invert max-w-none text-base-content/80">
                    {Phoenix.HTML.raw(@event.description)}
                  </div>
                </.card>
              <% end %>

              <%!-- Transportation Section --%>
              <%= if !@event.is_online and (@event.status == "public" || @event.transportation_options != [] || @event.carpools != []) do %>
                <.card size="lg" class="mb-6">
                  <h2 class="text-xl font-bold text-base-content mb-4 flex items-center gap-2">
                    <.icon name="hero-truck" class="w-5 h-5" />
                    {gettext("Transportation")}
                  </h2>

                  <%!-- Public/Bus Transportation --%>
                  <%= if @event.transportation_options != [] do %>
                    <div class="space-y-3 mb-6">
                      <div
                        :for={trans <- @event.transportation_options}
                        class="p-4 bg-base-100/50 rounded-lg border border-base-content/10"
                      >
                        <div class="flex items-start gap-3">
                          <div class="p-2 bg-primary/10 rounded-lg">
                            <.icon
                              name={transport_type_icon(trans.transport_type)}
                              class="w-5 h-5 text-primary"
                            />
                          </div>
                          <div class="flex-1">
                            <div class="flex items-center gap-2 mb-1">
                              <h4 class="font-semibold text-base-content">{trans.title}</h4>
                              <span class="px-2 py-0.5 bg-base-200 text-base-content/70 rounded text-xs">
                                {trans.transport_type}
                              </span>
                            </div>
                            <%= if trans.description do %>
                              <p class="text-sm text-base-content/60 mb-2">{trans.description}</p>
                            <% end %>
                            <div class="flex flex-wrap gap-4 text-xs text-base-content/50">
                              <%= if trans.departure_location do %>
                                <span class="flex items-center gap-1">
                                  <.icon name="hero-map-pin" class="w-3 h-3" />
                                  {trans.departure_location}
                                </span>
                              <% end %>
                              <%= if trans.departure_time do %>
                                <span class="flex items-center gap-1">
                                  <.icon name="hero-clock" class="w-3 h-3" />
                                  {format_time(trans.departure_time)}
                                </span>
                              <% end %>
                              <%= if trans.estimated_cost do %>
                                <span class="flex items-center gap-1">
                                  <.icon name="hero-currency-euro" class="w-3 h-3" />
                                  €{Decimal.to_string(trans.estimated_cost)}
                                </span>
                              <% end %>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  <% end %>

                  <%!-- Carpooling Section --%>
                  <div class="border-t border-base-content/10 pt-6">
                    <div class="flex items-center justify-between mb-4">
                      <h3 class="font-semibold text-base-content flex items-center gap-2">
                        <.icon name="hero-users" class="w-5 h-5" />
                        {gettext("Carpooling")}
                      </h3>
                      <div class="flex gap-2">
                        <%= if @event.status == "public" do %>
                          <%= if @confirmed_ride do %>
                            <div class="px-3 py-1.5 bg-success/10 text-success rounded-lg text-sm border border-success/20 flex items-center gap-2">
                              <.icon name="hero-check-circle" class="w-4 h-4" />
                              {gettext("Ride Confirmed")}
                            </div>
                          <% else %>
                            <%= unless @my_carpool do %>
                              <% has_pending =
                                Enum.any?(
                                  @ride_requests,
                                  &(&1.passenger_user_id == @current_scope.user.id)
                                ) %>
                              <%= if has_pending do %>
                                <div class="px-3 py-1.5 bg-warning/10 text-warning rounded-lg text-sm border border-warning/20 flex items-center gap-2">
                                  <.icon name="hero-clock" class="w-4 h-4" />
                                  {gettext("Request Pending")}
                                </div>
                              <% else %>
                                <button
                                  phx-click="show_request_form"
                                  class="px-3 py-1.5 bg-secondary text-secondary-content rounded-lg text-sm hover:bg-secondary/90"
                                >
                                  {gettext("Request a Ride")}
                                </button>
                              <% end %>
                              <button
                                phx-click="show_carpool_form"
                                class="px-3 py-1.5 bg-primary text-primary-content rounded-lg text-sm hover:bg-primary/90"
                              >
                                {gettext("Offer a Ride")}
                              </button>
                            <% else %>
                              <div class="px-3 py-1.5 bg-primary/10 text-primary rounded-lg text-sm border border-primary/20 flex items-center gap-2">
                                <.icon name="hero-check-badge" class="w-4 h-4" />
                                {gettext("You are offering a ride")}
                              </div>
                            <% end %>
                          <% end %>
                        <% end %>
                      </div>
                    </div>

                    <%!-- Confirmed Ride Details --%>
                    <%= if @confirmed_ride do %>
                      <div class="mb-6 p-4 bg-success/5 rounded-lg border border-success/20">
                        <h4 class="font-medium text-base-content mb-2 flex items-center justify-between gap-2">
                          <span class="flex items-center gap-2">
                            <.icon name="hero-check-circle" class="w-5 h-5 text-success" />
                            {gettext("Your Ride Details")}
                          </span>
                          <button
                            phx-click="leave_ride"
                            data-confirm={gettext("Are you sure you want to leave this ride?")}
                            class="text-xs text-error hover:underline"
                          >
                            {gettext("Leave Ride")}
                          </button>
                        </h4>
                        <p class="text-sm text-base-content/70 mb-4">
                          {gettext("You have a ride with %{driver}",
                            driver: @confirmed_ride.driver_user.email
                          )}
                        </p>
                        <div class="grid sm:grid-cols-2 gap-4 text-sm">
                          <div>
                            <p class="text-base-content/50">{gettext("Pick up")}</p>
                            <p class="font-medium">{@confirmed_ride.departure_location}</p>
                          </div>
                          <%= if @confirmed_ride.departure_time do %>
                            <div>
                              <p class="text-base-content/50">{gettext("Time")}</p>
                              <p class="font-medium">{format_time(@confirmed_ride.departure_time)}</p>
                            </div>
                          <% end %>

                          <%= if @confirmed_ride.departure_date do %>
                            <div>
                              <p class="text-base-content/50">{gettext("Date")}</p>
                              <p class="font-medium">{@confirmed_ride.departure_date}</p>
                            </div>
                          <% end %>
                          <%= if @confirmed_ride.cost do %>
                            <div>
                              <p class="text-base-content/50">{gettext("Cost")}</p>
                              <p class="font-medium">
                                <%= case @confirmed_ride.payment_method do %>
                                  <% "free" -> %>
                                    {gettext("Free")}
                                  <% "at_destination" -> %>
                                    €{@confirmed_ride.cost} ({gettext("At Destination")})
                                  <% "upfront" -> %>
                                    €{@confirmed_ride.cost} ({gettext("Upfront")})
                                  <% _ -> %>
                                    €{@confirmed_ride.cost}
                                <% end %>
                              </p>
                            </div>
                          <% end %>
                        </div>
                      </div>
                    <% end %>

                    <%!-- Request Form --%>
                    <%= if @show_request_form do %>
                      <div class="mb-6 p-4 bg-secondary/5 rounded-lg border border-secondary/20">
                        <h4 class="font-medium text-base-content mb-4">
                          {gettext("Request a Ride")}
                        </h4>
                        <.form
                          for={@request_form}
                          phx-change="validate_request"
                          phx-submit="create_request"
                        >
                          <div class="grid sm:grid-cols-2 gap-4 mb-4">
                            <.input
                              field={@request_form[:location]}
                              type="text"
                              label={gettext("Pickup Location")}
                              placeholder={gettext("e.g., Downtown")}
                              required
                            />
                            <.input
                              field={@request_form[:contact_info]}
                              type="text"
                              label={gettext("Contact Info")}
                              placeholder={gettext("Phone or Email")}
                              required
                            />
                          </div>
                          <div class="flex gap-2 mt-4">
                            <.primary_button type="submit">{gettext("Post Request")}</.primary_button>
                            <.secondary_button type="button" phx-click="hide_request_form">
                              {gettext("Cancel")}
                            </.secondary_button>
                          </div>
                        </.form>
                      </div>
                    <% end %>

                    <%!-- Ride Requests List --%>
                    <%= if @ride_requests != [] do %>
                      <div class="mb-6">
                        <h4 class="text-sm font-semibold text-base-content uppercase tracking-wider mb-3">
                          {gettext("Ride Requests")}
                        </h4>
                        <div class="grid sm:grid-cols-2 gap-4">
                          <div
                            :for={req <- @ride_requests}
                            class="p-3 bg-base-100/50 rounded-lg border border-base-content/10 flex items-center justify-between"
                          >
                            <div>
                              <p class="font-medium text-base-content">
                                {req.passenger_user.email |> String.split("@") |> List.first()}
                              </p>
                              <p class="text-sm text-base-content/60">
                                <.icon name="hero-map-pin" class="w-3 h-3 inline" /> {req.location}
                              </p>
                            </div>

                            <%= if @my_carpool && req.status == "pending" do %>
                              <button
                                phx-click="pick_up_passenger"
                                phx-value-request_id={req.id}
                                class="px-3 py-1 bg-primary text-primary-content rounded text-xs hover:bg-primary/90 transition-colors"
                              >
                                {gettext("Pick Up")}
                              </button>
                            <% else %>
                              <span class={[
                                "px-2 py-1 rounded text-xs font-medium",
                                if(req.status == "fulfilled",
                                  do: "bg-success/10 text-success",
                                  else: "bg-base-200 text-base-content/60"
                                )
                              ]}>
                                <%= if req.status == "fulfilled" do %>
                                  {gettext("Ride Found")}
                                <% else %>
                                  {gettext("Looking for ride")}
                                <% end %>
                              </span>
                              <%= if req.passenger_user_id == @current_scope.user.id do %>
                                <button
                                  phx-click="delete_ride_request"
                                  phx-value-request_id={req.id}
                                  class="ml-2 text-error hover:text-error/80"
                                  data-confirm={gettext("Cancel request?")}
                                >
                                  <.icon name="hero-trash" class="w-4 h-4" />
                                </button>
                              <% end %>
                            <% end %>
                          </div>
                        </div>
                      </div>
                    <% end %>

                    <%!-- Carpool Form --%>
                    <%= if @show_carpool_form do %>
                      <div class="mb-6 p-4 bg-primary/5 rounded-lg border border-primary/20">
                        <h4 class="font-medium text-base-content mb-4">{gettext("Offer a Ride")}</h4>
                        <.form
                          for={@carpool_form}
                          phx-change="validate_carpool"
                          phx-submit="create_carpool"
                        >
                          <div class="grid sm:grid-cols-2 gap-4 mb-4">
                            <.input
                              field={@carpool_form[:departure_location]}
                              type="text"
                              label={gettext("Pickup Location")}
                              placeholder={gettext("e.g., City Center, Train Station")}
                              required
                            />
                            <.input
                              field={@carpool_form[:available_seats]}
                              type="number"
                              label={gettext("Available Seats")}
                              min="1"
                              max="8"
                              required
                            />
                          </div>
                          <div class="grid sm:grid-cols-2 gap-4 mb-4">
                            <.input
                              field={@carpool_form[:departure_time]}
                              type="time"
                              label={gettext("Departure Time")}
                            />
                            <.input
                              field={@carpool_form[:contact_phone]}
                              type="tel"
                              label={gettext("Contact Phone")}
                            />
                          </div>
                          <.input
                            field={@carpool_form[:notes]}
                            type="textarea"
                            label={gettext("Additional Notes")}
                            rows="2"
                          />
                          <div class="grid sm:grid-cols-2 gap-4 mb-4">
                            <.input
                              field={@carpool_form[:departure_date]}
                              type="date"
                              label={gettext("Departure Date")}
                              value={@carpool_form[:departure_date].value || @event.event_date}
                            />
                            <div>
                              <label class="block text-sm font-semibold leading-6 text-base-content mb-2">
                                {gettext("Payment Method")}
                              </label>
                              <.input
                                field={@carpool_form[:payment_method]}
                                type="select"
                                options={[
                                  {gettext("Free"), "free"},
                                  {gettext("Pay at Destination / Flexible Cost"), "at_destination"},
                                  {gettext("Upfront"), "upfront"}
                                ]}
                              />
                            </div>
                          </div>
                          <%= if @carpool_form[:payment_method].value == "upfront" do %>
                            <div class="mb-4">
                              <.input
                                field={@carpool_form[:cost]}
                                type="number"
                                label={gettext("Cost per Seat (€)")}
                                step="0.01"
                                min="0"
                              />
                            </div>
                          <% end %>
                          <div class="flex gap-2 mt-4">
                            <.primary_button type="submit">{gettext("Create Offer")}</.primary_button>
                            <.secondary_button type="button" phx-click="hide_carpool_form">
                              {gettext("Cancel")}
                            </.secondary_button>
                          </div>
                        </.form>
                      </div>
                    <% end %>

                    <%!-- Carpool List --%>
                    <%= if @event.carpools != [] do %>
                      <div class="grid sm:grid-cols-2 gap-4">
                        <div
                          :for={carpool <- @event.carpools}
                          class={[
                            "p-4 rounded-lg border",
                            "border-#{carpool_status_color(carpool)}/30 bg-#{carpool_status_color(carpool)}/5"
                          ]}
                        >
                          <div class="flex items-start justify-between mb-3">
                            <div>
                              <p class="font-medium text-base-content">
                                {carpool.driver_user.email |> String.split("@") |> List.first()}
                              </p>
                              <p class="text-sm text-base-content/60">{carpool.departure_location}</p>
                            </div>
                            <div class="text-right">
                              <span class={[
                                "px-2 py-1 rounded-full text-xs font-medium",
                                "bg-#{carpool_status_color(carpool)}/10 text-#{carpool_status_color(carpool)}"
                              ]}>
                                {EventCarpool.remaining_seats(carpool)}/{carpool.available_seats} {gettext(
                                  "seats"
                                )}
                              </span>
                              <%= if carpool.driver_user_id == @current_scope.user.id do %>
                                <button
                                  phx-click="delete_carpool"
                                  phx-value-carpool_id={carpool.id}
                                  data-confirm={
                                    gettext(
                                      "Are you sure? This will cancel the ride for all passengers."
                                    )
                                  }
                                  class="ml-2 text-error hover:text-error/80"
                                >
                                  <.icon name="hero-trash" class="w-4 h-4" />
                                </button>
                              <% end %>
                            </div>
                          </div>

                          <div class="flex flex-wrap gap-x-4 gap-y-1 text-xs text-base-content/60 mb-2">
                            <%= if carpool.departure_date do %>
                              <p class="flex items-center gap-1">
                                <.icon name="hero-calendar" class="w-3 h-3" />
                                {Calendar.strftime(carpool.departure_date, "%b %d, %Y")}
                              </p>
                            <% end %>
                            <%= if carpool.departure_time do %>
                              <p class="flex items-center gap-1">
                                <.icon name="hero-clock" class="w-3 h-3" />
                                {format_time(carpool.departure_time)}
                              </p>
                            <% end %>
                          </div>

                          <p class="text-xs text-base-content/60 mb-2 flex items-center gap-1">
                            <.icon name="hero-banknotes" class="w-3 h-3" />
                            <%= case carpool.payment_method do %>
                              <% "free" -> %>
                                <span class="text-success font-medium">{gettext("Free")}</span>
                              <% "at_destination" -> %>
                                <span>{gettext("Pay at Destination / Flexible Cost")}</span>
                              <% "upfront" -> %>
                                <span>
                                  {gettext("Upfront")}:
                                  <span class="font-medium text-base-content">€{carpool.cost}</span>
                                </span>
                              <% _ -> %>
                                <span>{gettext("Flexible")}</span>
                            <% end %>
                          </p>

                          <%!-- Accepted Passengers --%>
                          <% accepted = Enum.filter(carpool.requests, &(&1.status == "accepted")) %>
                          <%= if accepted != [] do %>
                            <div class="mb-3">
                              <p class="text-xs text-base-content/50 mb-1">
                                {gettext("Passengers")}:
                              </p>
                              <div class="flex flex-wrap gap-1">
                                <% visible_passengers = Enum.take(accepted, 5) %>
                                <% remaining_count = length(accepted) - length(visible_passengers) %>
                                <span
                                  :for={req <- visible_passengers}
                                  class="px-2 py-0.5 bg-success/10 text-success rounded text-xs"
                                >
                                  {req.passenger_user.email |> String.split("@") |> List.first()}
                                </span>
                                <%= if remaining_count > 0 do %>
                                  <span class="px-2 py-0.5 bg-base-content/10 text-base-content/60 rounded text-xs">
                                    +{remaining_count} {gettext("more")}
                                  </span>
                                <% end %>
                              </div>
                            </div>
                          <% end %>

                          <%!-- Pending Requests (Driver Only) --%>
                          <% pending = Enum.filter(carpool.requests, &(&1.status == "pending")) %>
                          <%= if pending != [] && carpool.driver_user_id == @current_scope.user.id do %>
                            <div class="mb-3 pt-3 border-t border-base-content/10">
                              <p class="text-xs font-bold text-warning mb-2">
                                {gettext("Pending Requests")}
                              </p>
                              <div class="space-y-2">
                                <div
                                  :for={req <- pending}
                                  class="flex items-center justify-between p-2 bg-warning/10 rounded-lg"
                                >
                                  <span class="text-xs text-base-content font-medium">
                                    {req.passenger_user.email |> String.split("@") |> List.first()}
                                  </span>
                                  <div class="flex gap-1">
                                    <button
                                      phx-click="accept_request"
                                      phx-value-request_id={req.id}
                                      class="px-2 py-1 bg-success text-success-content rounded text-xs hover:bg-success/90"
                                    >
                                      {gettext("Accept")}
                                    </button>
                                    <button
                                      phx-click="reject_request"
                                      phx-value-request_id={req.id}
                                      class="px-2 py-1 bg-error text-error-content rounded text-xs hover:bg-error/90"
                                    >
                                      {gettext("Decline")}
                                    </button>
                                  </div>
                                </div>
                              </div>
                            </div>
                          <% end %>

                          <%= if carpool.status == "open" && EventCarpool.remaining_seats(carpool) > 0 && carpool.driver_user_id != @current_scope.user.id do %>
                            <% my_request =
                              Enum.find(
                                carpool.requests,
                                &(&1.passenger_user_id == @current_scope.user.id)
                              ) %>
                            <%= if my_request do %>
                              <%= if my_request.status == "pending" do %>
                                <%= if my_request.status == "pending" do %>
                                  <button
                                    phx-click="cancel_carpool_request"
                                    phx-value-carpool_id={carpool.id}
                                    class="text-xs text-warning hover:underline"
                                  >
                                    {gettext("Request pending... (Cancel)")}
                                  </button>
                                <% end %>
                              <% end %>
                              <%= if my_request.status == "accepted" do %>
                                <span class="text-xs text-success">{gettext("Seat Confirmed")}</span>
                              <% end %>
                            <% else %>
                              <button
                                phx-click="request_carpool"
                                phx-value-carpool_id={carpool.id}
                                class="w-full px-3 py-2 bg-primary text-primary-content rounded-lg text-sm hover:bg-primary/90"
                              >
                                {gettext("Request Seat")}
                              </button>
                            <% end %>
                          <% end %>
                        </div>
                      </div>
                    <% else %>
                      <p class="text-sm text-base-content/50 text-center py-4">
                        {gettext("No carpool offers yet. Be the first to offer a ride!")}
                      </p>
                    <% end %>
                  </div>
                </.card>
              <% end %>

              <%!-- Tasks Section (for organizers/team and attendees) --%>
              <%= if (@can_edit || (@attendance && @attendance.status == "attending")) && @event.tasks != [] do %>
                <.card size="lg" class="mb-6">
                  <h2 class="text-xl font-bold text-base-content mb-4 flex items-center gap-2">
                    <.icon name="hero-clipboard-document-check" class="w-5 h-5" />
                    {gettext("Tasks")}
                  </h2>

                  <div class="space-y-3">
                    <div
                      :for={task <- @event.tasks}
                      class="p-4 bg-base-100/50 rounded-lg border border-base-content/10 flex flex-col sm:flex-row justify-between gap-4"
                    >
                      <div class="space-y-2 grow">
                        <div class="flex items-center gap-3 flex-wrap">
                          <span class={[
                            "px-2 py-1 rounded text-xs font-medium",
                            task_status_class(task.status)
                          ]}>
                            {task.status}
                          </span>
                          <span class="text-base-content font-medium">{task.title}</span>
                        </div>
                        <%= if task.description do %>
                          <p class="text-sm text-base-content/70">{task.description}</p>
                        <% end %>

                        <div class="flex flex-wrap gap-4 text-xs text-base-content/60">
                          <span class="flex items-center gap-1">
                            <.icon name="hero-calendar" class="w-3 h-3" />
                            {gettext("Start")}: {if task.start_date,
                              do: Calendar.strftime(task.start_date, "%b %d, %Y"),
                              else: "TBD"}
                          </span>
                          <span class="flex items-center gap-1">
                            <.icon name="hero-flag" class="w-3 h-3" />
                            {gettext("Due")}: {if task.due_date,
                              do: Calendar.strftime(task.due_date, "%b %d, %Y"),
                              else: "TBD"}
                          </span>
                        </div>

                        <%!-- Assigned User (Legacy/Lead) --%>
                        <%= if task.assigned_user do %>
                          <div class="text-xs text-base-content/50">
                            {gettext("Lead")}: {task.assigned_user.email
                            |> String.split("@")
                            |> List.first()}
                          </div>
                        <% end %>

                        <%!-- Volunteers --%>
                        <%= if task.volunteers != [] do %>
                          <div class="flex flex-wrap gap-2 items-center">
                            <span class="text-xs text-base-content/60">{gettext("Volunteers")}:</span>
                            <span
                              :for={vol <- task.volunteers}
                              class="px-2 py-1 bg-primary/10 text-primary rounded-full text-xs"
                            >
                              {vol.email |> String.split("@") |> List.first()}
                            </span>
                          </div>
                        <% end %>
                      </div>

                      <div class="shrink-0 flex items-start gap-3">
                        <%= if task.actual_expense do %>
                          <span class="text-sm text-base-content/60 pt-1">
                            €{Decimal.to_string(task.actual_expense)}
                          </span>
                        <% end %>

                        <%!-- Action Buttons --%>
                        <%= if @attendance && @attendance.status == "attending" do %>
                          <% am_volunteering =
                            Enum.any?(task.volunteers, &(&1.id == @current_scope.user.id)) %>
                          <%= if am_volunteering do %>
                            <button
                              phx-click="leave_task"
                              phx-value-task_id={task.id}
                              class="px-3 py-1.5 bg-error/10 text-error text-xs font-medium rounded hover:bg-error/20 transition-colors"
                            >
                              {gettext("Leave Task")}
                            </button>
                          <% else %>
                            <button
                              phx-click="volunteer_task"
                              phx-value-task_id={task.id}
                              class="px-3 py-1.5 bg-primary/10 text-primary text-xs font-medium rounded hover:bg-primary/20 transition-colors"
                            >
                              {gettext("Volunteer")}
                            </button>
                          <% end %>
                        <% end %>
                      </div>
                    </div>
                  </div>
                </.card>
              <% end %>
            </div>
            <div class="space-y-6">
              <%!-- Invitation Section --%>
              <%= if @event.invitation_type != "none" && @event.invitation_url do %>
                <.card size="lg" class="mb-6">
                  <h2 class="text-xl font-bold text-base-content mb-4 flex items-center gap-2">
                    <.icon name="hero-envelope-open" class="w-5 h-5" />
                    {gettext("Invitation")}
                  </h2>
                  <%= if @event.invitation_type == "image" do %>
                    <img
                      src={@event.invitation_url}
                      alt={gettext("Event invitation")}
                      class="max-w-full rounded-lg"
                    />
                  <% else %>
                    <a
                      href={@event.invitation_url}
                      target="_blank"
                      rel="noopener"
                      class="inline-flex items-center gap-2 px-4 py-2 bg-primary text-primary-content rounded-lg hover:bg-primary/90"
                    >
                      <.icon name="hero-document" class="w-5 h-5" />
                      {gettext("View Invitation PDF")}
                    </a>
                  <% end %>
                </.card>
              <% end %>

              <%!-- Location Section --%>
              <%= if @event.venue_name || @event.address || @event.google_maps_embed_url do %>
                <.card size="lg" class="mb-6">
                  <h2 class="text-xl font-bold text-base-content mb-4 flex items-center gap-2">
                    <.icon name="hero-map-pin" class="w-5 h-5" />
                    {gettext("Location")}
                  </h2>

                  <div class="grid md:grid-cols-2 gap-6">
                    <div>
                      <%= if @event.venue_name do %>
                        <h3 class="font-semibold text-lg text-base-content mb-2">
                          {@event.venue_name}
                        </h3>
                      <% end %>
                      <%= if @event.address do %>
                        <p class="text-base-content/70 mb-3">{@event.address}</p>
                      <% end %>
                      <p class="text-base-content/60 mb-4">
                        {[@event.city, @event.country] |> Enum.reject(&is_nil/1) |> Enum.join(", ")}
                      </p>

                      <div class="flex flex-wrap gap-2">
                        <%= if @event.google_maps_link do %>
                          <a
                            href={@event.google_maps_link}
                            target="_blank"
                            rel="noopener"
                            class="inline-flex items-center gap-2 px-3 py-2 bg-base-200 text-base-content rounded-lg hover:bg-base-300 text-sm"
                          >
                            <.icon name="hero-arrow-top-right-on-square" class="w-4 h-4" />
                            {gettext("Open in Maps")}
                          </a>
                        <% end %>
                        <%= if @event.venue_website do %>
                          <a
                            href={@event.venue_website}
                            target="_blank"
                            rel="noopener"
                            class="inline-flex items-center gap-2 px-3 py-2 bg-base-200 text-base-content rounded-lg hover:bg-base-300 text-sm"
                          >
                            <.icon name="hero-globe-alt" class="w-4 h-4" />
                            {gettext("Venue Website")}
                          </a>
                        <% end %>
                      </div>
                    </div>

                    <%= if @event.google_maps_embed_url do %>
                      <div class="aspect-video rounded-lg overflow-hidden bg-base-200">
                        <iframe
                          src={@event.google_maps_embed_url}
                          width="100%"
                          height="100%"
                          style="border:0;"
                          allowfullscreen=""
                          loading="lazy"
                          referrerpolicy="no-referrer-when-downgrade"
                        >
                        </iframe>
                      </div>
                    <% end %>
                  </div>

                  <%!-- Location Photos --%>
                  <%= if @event.location_photos != [] do %>
                    <div class="mt-6 pt-6 border-t border-base-content/10">
                      <h3 class="font-semibold text-base-content mb-3">{gettext("Venue Photos")}</h3>
                      <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
                        <div
                          :for={photo <- @event.location_photos}
                          class="aspect-square rounded-lg overflow-hidden bg-base-200"
                        >
                          <img
                            src={photo.photo_url}
                            alt={photo.caption || gettext("Venue photo")}
                            class="w-full h-full object-cover"
                          />
                        </div>
                      </div>
                    </div>
                  <% end %>
                </.card>
              <% end %>

              <%!-- Budget Section --%>
              <%= if @event.budget_total || @event.budget_notes || @event.resources_required do %>
                <.card size="lg" class="mb-6">
                  <h2 class="text-xl font-bold text-base-content mb-4 flex items-center gap-2">
                    <.icon name="hero-currency-euro" class="w-5 h-5" />
                    {gettext("Budget & Resources")}
                  </h2>

                  <%= if @event.budget_total do %>
                    <div class="mb-4 p-4 bg-base-100/50 rounded-lg">
                      <p class="text-sm text-base-content/60 mb-1">{gettext("Total Budget")}</p>
                      <p class="text-2xl font-bold text-base-content">
                        €{Decimal.to_string(@event.budget_total)}
                      </p>
                    </div>
                  <% end %>

                  <%= if @event.budget_notes do %>
                    <div class="mb-4">
                      <p class="text-sm font-medium text-base-content mb-2">
                        {gettext("Budget Notes")}
                      </p>
                      <p class="text-base-content/70">{@event.budget_notes}</p>
                    </div>
                  <% end %>

                  <%= if @event.resources_required do %>
                    <div>
                      <p class="text-sm font-medium text-base-content mb-2">
                        {gettext("Resources Required")}
                      </p>
                      <p class="text-base-content/70">{@event.resources_required}</p>
                    </div>
                  <% end %>
                </.card>
              <% end %>
            </div>
          </div>

          <%!-- Financial Summary (for organizers only) --%>
          <%= if !@event.is_online and @can_edit do %>
            <.card size="lg" class="mb-6">
              <h2 class="text-xl font-bold text-base-content mb-4 flex items-center gap-2">
                <.icon name="hero-chart-bar" class="w-5 h-5" />
                {gettext("Financial Summary")}
              </h2>

              <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div class="p-4 bg-success/10 rounded-lg text-center">
                  <p class="text-xs text-success mb-1">{gettext("Income")}</p>
                  <p class="text-xl font-bold text-success">
                    €{Decimal.to_string(@financial.total_income)}
                  </p>
                </div>
                <div class="p-4 bg-error/10 rounded-lg text-center">
                  <p class="text-xs text-error mb-1">{gettext("Expenses")}</p>
                  <p class="text-xl font-bold text-error">
                    €{Decimal.to_string(@financial.total_expenses)}
                  </p>
                </div>
                <div class={[
                  "p-4 rounded-lg text-center",
                  if(@financial.is_profit, do: "bg-success/10", else: "bg-error/10")
                ]}>
                  <p class={[
                    "text-xs mb-1",
                    if(@financial.is_profit, do: "text-success", else: "text-error")
                  ]}>
                    {gettext("Balance")}
                  </p>
                  <p class={[
                    "text-xl font-bold",
                    if(@financial.is_profit, do: "text-success", else: "text-error")
                  ]}>
                    €{Decimal.to_string(@financial.balance)}
                  </p>
                </div>
                <div class="p-4 bg-base-100/50 rounded-lg text-center">
                  <p class="text-xs text-base-content/60 mb-1">{gettext("Donations")}</p>
                  <p class="text-xl font-bold text-base-content">{length(@event.donations)}</p>
                </div>
              </div>
            </.card>
          <% end %>

          <%!-- Donation Section --%>
          <%= if @event.banking_iban do %>
            <.card size="lg" class="mb-6">
              <h2 class="text-xl font-bold text-base-content mb-4 flex items-center gap-2">
                <.icon name="hero-heart" class="w-5 h-5 text-error" />
                {gettext("Support This Event")}
              </h2>

              <p class="text-base-content/70 mb-4">
                {gettext("Your donation helps make this event possible. Thank you for your support!")}
              </p>

              <div class="p-4 bg-base-100/50 rounded-lg border border-base-content/10 space-y-2">
                <%= if @event.banking_name do %>
                  <div class="flex justify-between">
                    <span class="text-sm text-base-content/60">{gettext("Account Name")}</span>
                    <span class="text-sm font-medium text-base-content">{@event.banking_name}</span>
                  </div>
                <% end %>
                <div class="flex justify-between">
                  <span class="text-sm text-base-content/60">{gettext("IBAN")}</span>
                  <span class="text-sm font-mono font-medium text-base-content">
                    {@event.banking_iban}
                  </span>
                </div>
                <%= if @event.banking_swift do %>
                  <div class="flex justify-between">
                    <span class="text-sm text-base-content/60">{gettext("SWIFT/BIC")}</span>
                    <span class="text-sm font-mono font-medium text-base-content">
                      {@event.banking_swift}
                    </span>
                  </div>
                <% end %>
                <%= if @event.banking_notes do %>
                  <div class="pt-2 border-t border-base-content/10">
                    <p class="text-sm text-base-content/70">{@event.banking_notes}</p>
                  </div>
                <% end %>
              </div>
            </.card>
          <% end %>
        <% end %>
      </div>
    </.page_container>
    """
  end
end

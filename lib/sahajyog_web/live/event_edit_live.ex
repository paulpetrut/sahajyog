defmodule SahajyogWeb.EventEditLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Repo
  alias Sahajyog.Accounts
  alias Sahajyog.Events
  alias Sahajyog.Events.{Event, EventTask, EventTransportation, EventTeamMember, EventNotifier}

  @tabs ~w(basic location transportation tasks team finances)

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    user = socket.assigns.current_scope.user
    timezones = Timex.timezones()

    if !Sahajyog.Accounts.User.profile_complete?(user) do
      return_path = ~p"/events/#{slug}/edit"
      encoded_return = URI.encode_www_form(return_path)

      {:ok,
       socket
       |> put_flash(
         :error,
         gettext(
           "Please complete your profile (First Name, Last Name, Phone Number) before managing an event."
         )
       )
       |> push_navigate(to: ~p"/users/settings?return_to=#{encoded_return}")}
    else
      event = Events.get_event_by_slug!(slug)

      if connected?(socket) do
        Events.subscribe(event.id)
      end

      if Events.can_edit_event?(socket.assigns.current_scope, event) do
        changeset = Events.change_event(event)

        # Strip HTML tags from description for the form if it exists
        changeset =
          if changeset.data.description do
            clean_desc = strip_html(changeset.data.description)
            Ecto.Changeset.put_change(changeset, :description, clean_desc)
          else
            changeset
          end

        {:ok,
         socket
         |> assign(:page_title, "Edit #{event.title}")
         |> assign(:event, event)
         |> assign(:form, to_form(changeset))
         |> assign(:tabs, @tabs)
         |> assign(:current_tab, "basic")
         # Data needed for forms
         |> assign(:show_task_modal, false)
         |> assign(:editing_task, nil)
         # Initialize for new task
         |> assign(:task_form, to_form(Events.change_task(%EventTask{})))
         |> assign(:show_transport_modal, false)
         # Initialize for new transport
         |> assign(:transport_form, to_form(Events.change_transportation(%EventTransportation{})))
         |> assign(:invite_email, "")
         |> assign(:invite_form, to_form(%{}, as: :invite))
         |> assign(:current_scope, socket.assigns.current_scope)
         # For finances
         # Placeholder logic?
         |> assign(:transactions, Events.list_donations(event.id))
         |> assign(:timezones, timezones)}
      else
        {:ok,
         socket
         |> put_flash(:error, gettext("You cannot edit this event"))
         |> push_navigate(to: ~p"/events/#{event.slug}")}
      end
    end
  end

  @impl true
  def handle_info({:event_updated, event_id}, socket) do
    if socket.assigns.event.id == event_id do
      # Refresh event data to see new team members, etc.
      # We need to preserve current tab state but reload the event struct
      event = Events.get_event!(event_id)

      # Also need to re-check edit permissions just in case
      if Events.can_edit_event?(socket.assigns.current_scope, event) do
        {:noreply, assign(socket, :event, event)}
      else
        {:noreply,
         socket
         |> put_flash(:error, gettext("You no longer have permission to edit this event"))
         |> push_navigate(to: ~p"/events/#{event.slug}")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :current_tab, tab)}
  end

  @impl true
  def handle_event("validate", %{"event" => event_params}, socket) do
    changeset =
      socket.assigns.event
      |> Events.change_event(event_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"event" => event_params}, socket) do
    case Events.update_event(socket.assigns.event, event_params) do
      {:ok, event} ->
        msg =
          case socket.assigns.current_tab do
            "basic" -> gettext("Basic info updated successfully")
            "location" -> gettext("Location updated successfully")
            "finances" -> gettext("Budget & Finances updated successfully")
            _ -> gettext("Event updated successfully")
          end

        {:noreply,
         socket
         |> assign(:event, event)
         |> assign(:form, to_form(Events.change_event(event)))
         |> put_flash(:info, msg)}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("publish", _, socket) do
    case Events.update_event(socket.assigns.event, %{status: "public"}) do
      {:ok, event} ->
        {:noreply,
         socket
         |> assign(:event, event)
         |> assign(:form, to_form(Events.change_event(event)))
         |> put_flash(:info, gettext("Event published successfully!"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Could not publish event"))}
    end
  end

  # Transportation Management
  def handle_event("add_transport", _, socket) do
    changeset = Events.change_transportation(%EventTransportation{})

    {:noreply,
     socket
     |> assign(:show_transport_modal, true)
     |> assign(:transport_form, to_form(changeset))}
  end

  def handle_event("validate_transport", %{"event_transportation" => params}, socket) do
    changeset =
      %EventTransportation{}
      |> Events.change_transportation(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :transport_form, to_form(changeset))}
  end

  def handle_event("save_transport", %{"event_transportation" => params}, socket) do
    params = Map.put(params, "event_id", socket.assigns.event.id)

    case Events.create_transportation(params) do
      {:ok, _} ->
        event = Events.get_event!(socket.assigns.event.id)

        {:noreply,
         socket
         |> assign(:event, event)
         |> assign(:show_transport_modal, false)
         |> put_flash(:info, gettext("Transportation option added"))}

      {:error, changeset} ->
        {:noreply, assign(socket, :transport_form, to_form(changeset))}
    end
  end

  def handle_event("delete_transport", %{"id" => id}, socket) do
    transport = Repo.get!(EventTransportation, id)
    {:ok, _} = Events.delete_transportation(transport)
    event = Events.get_event!(socket.assigns.event.id)

    {:noreply,
     socket
     |> assign(:event, event)
     |> put_flash(:info, gettext("Transportation option deleted"))}
  end

  def handle_event("cancel_transport_modal", _, socket) do
    {:noreply, assign(socket, :show_transport_modal, false)}
  end

  # Task Management
  def handle_event("add_task", _, socket) do
    changeset = Events.change_task(%EventTask{})

    {:noreply,
     socket
     |> assign(:editing_task, nil)
     |> assign(:show_task_modal, true)
     |> assign(:task_form, to_form(changeset))}
  end

  def handle_event("edit_task", %{"id" => id}, socket) do
    task = Events.get_task!(id)
    changeset = Events.change_task(task)

    {:noreply,
     socket
     |> assign(:editing_task, task)
     |> assign(:show_task_modal, true)
     |> assign(:task_form, to_form(changeset))}
  end

  def handle_event("validate_task", %{"event_task" => params}, socket) do
    changeset =
      %EventTask{}
      |> Events.change_task(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :task_form, to_form(changeset))}
  end

  def handle_event("save_task", %{"event_task" => params}, socket) do
    params = Map.put(params, "event_id", socket.assigns.event.id)

    result =
      if socket.assigns.editing_task do
        Events.update_task(socket.assigns.editing_task, params)
      else
        Events.create_task(params)
      end

    case result do
      {:ok, _} ->
        event = Events.get_event!(socket.assigns.event.id)

        msg =
          if socket.assigns.editing_task,
            do: gettext("Task updated successfully"),
            else: gettext("Task added successfully")

        {:noreply,
         socket
         |> assign(:event, event)
         |> assign(:show_task_modal, false)
         |> put_flash(:info, msg)}

      {:error, changeset} ->
        {:noreply, assign(socket, :task_form, to_form(changeset))}
    end
  end

  def handle_event("delete_task", %{"id" => id}, socket) do
    task = Repo.get!(EventTask, id)
    {:ok, _} = Events.delete_task(task)
    event = Events.get_event!(socket.assigns.event.id)

    {:noreply,
     socket
     |> assign(:event, event)
     |> put_flash(:info, gettext("Task deleted"))}
  end

  def handle_event("cancel_task_modal", _, socket) do
    {:noreply, assign(socket, :show_task_modal, false)}
  end

  # Team Management
  def handle_event("invite_collaborator", %{"email" => email}, socket) do
    email = String.trim(email)

    cond do
      email == "" ->
        {:noreply, put_flash(socket, :error, gettext("Please enter an email address."))}

      email == socket.assigns.current_scope.user.email ->
        {:noreply, put_flash(socket, :error, gettext("You cannot invite yourself."))}

      true ->
        case Accounts.get_user_by_email(email) do
          nil ->
            {:noreply, put_flash(socket, :error, gettext("User not found with that email."))}

          user ->
            # Check if already a member
            if Enum.any?(socket.assigns.event.team_members, &(&1.user_id == user.id)) do
              {:noreply, put_flash(socket, :error, gettext("User is already a team member."))}
            else
              case Events.invite_team_member(
                     socket.assigns.current_scope,
                     socket.assigns.event.id,
                     user.id,
                     "co_author"
                   ) do
                {:ok, _member} ->
                  event = Events.get_event!(socket.assigns.event.id)

                  # Send invitation email
                  # We use the event show page as the destination for both accept/reject
                  # as the UI there handles the invitation logic.
                  # Note: We need a full URL, but here we only have path helpers.
                  # Ideally we should use url/1 but we might not have Endpoint alias here.
                  # We can assume relative path is fine if email client opens browser?
                  # No, email needs absolute URL.
                  # Let's try to get full URL using SahajyogWeb.Endpoint.url() + path.
                  base_url = SahajyogWeb.Endpoint.url()
                  event_path = ~p"/events/#{event.slug}"
                  full_url = "#{base_url}#{event_path}"

                  EventNotifier.deliver_invitation_email(
                    user.email,
                    event.title,
                    "#{socket.assigns.current_scope.user.first_name} #{socket.assigns.current_scope.user.last_name}",
                    full_url,
                    full_url
                  )

                  {:noreply,
                   socket
                   |> assign(:event, event)
                   |> assign(:invite_email, "")
                   |> put_flash(:info, gettext("Invitation sent to %{email}", email: email))}

                {:error, _} ->
                  {:noreply, put_flash(socket, :error, gettext("Could not send invitation."))}
              end
            end
        end
    end
  end

  def handle_event("remove_collaborator", %{"id" => id}, socket) do
    # Verify owner? Or let any editor remove?
    # Usually owner should control this. Co-owners might remove others?
    # Requirement: "owner... can add... co-owner(s)".
    # Safe to allow removal by editor for now (as privileges are same).
    member = Repo.get!(EventTeamMember, id) |> Repo.preload(:user)
    event = Events.get_event!(socket.assigns.event.id)

    # Send removal email
    EventNotifier.deliver_team_removal_email(member.user.email, event.title)

    {:ok, _} = Events.remove_team_member(member)
    event = Events.get_event!(socket.assigns.event.id)

    {:noreply,
     socket
     |> assign(:event, event)
     |> put_flash(:info, gettext("Team member removed."))}
  end

  defp strip_html(nil), do: nil

  defp strip_html(html) do
    html
    |> String.replace(~r/<br\s*\/?>/i, "\n")
    |> String.replace(~r/<\/p>/i, "\n")
    |> String.replace(~r/<[^>]+>/, "")
    |> String.trim()
  end

  defp tab_class(current_tab, tab) do
    if current_tab == tab do
      "px-4 py-2 border-b-2 border-primary text-primary font-medium"
    else
      "px-4 py-2 border-b-2 border-transparent text-base-content/60 hover:text-base-content"
    end
  end

  defp tab_label("basic"), do: gettext("Basic Info")
  defp tab_label("location"), do: gettext("Location")
  defp tab_label("transportation"), do: gettext("Transportation")
  defp tab_label("tasks"), do: gettext("Tasks")
  defp tab_label("finances"), do: gettext("Finances")
  defp tab_label("team"), do: gettext("Team")

  # For task status badge

  defp task_status_class("pending"), do: "bg-base-content/10 text-base-content/60"
  defp task_status_class("in_progress"), do: "bg-info/10 text-info"
  defp task_status_class("completed"), do: "bg-success/10 text-success"
  defp task_status_class(_), do: "bg-base-content/10 text-base-content/60"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.page_container>
        <%= if @show_task_modal do %>
          <.task_modal form={@task_form} />
        <% end %>

        <%= if @show_transport_modal do %>
          <.transport_modal form={@transport_form} />
        <% end %>

        <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <%!-- Header --%>
          <%!-- Header --%>
          <Layouts.events_nav current_page={
            if @event.user_id == @current_scope.user.id, do: :my_events, else: :list
          } />
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
            <div>
              <.link
                navigate={~p"/events/#{@event.slug}"}
                class="text-info hover:text-info/80 mb-2 inline-flex items-center gap-2"
              >
                <.icon name="hero-arrow-left" class="w-4 h-4" />
                {gettext("Back to Event")}
              </.link>
              <h1 class="text-2xl sm:text-3xl font-bold text-base-content">{@event.title}</h1>
            </div>

            <%= if @event.status == "draft" do %>
              <button
                phx-click="publish"
                class="px-6 py-3 bg-success text-success-content rounded-lg hover:bg-success/90 font-semibold flex items-center gap-2"
              >
                <.icon name="hero-globe-alt" class="w-5 h-5" />
                {gettext("Publish Event")}
              </button>
            <% end %>
          </div>

          <%!-- Tabs --%>
          <div class="border-b border-base-content/10 mb-6">
            <nav class="flex gap-1 overflow-x-auto">
              <button
                :for={tab <- @tabs}
                phx-click="change_tab"
                phx-value-tab={tab}
                class={tab_class(@current_tab, tab)}
              >
                {tab_label(tab)}
              </button>
            </nav>
          </div>

          <%!-- Tab Content --%>
          <.card size="lg">
            <%= if @current_tab in ["basic", "location", "finances"] do %>
              <.form for={@form} id="event-form" phx-change="validate" phx-submit="save">
                <%!-- Basic Info Tab --%>
                <div :if={@current_tab == "basic"} class="space-y-6">
                  <.input field={@form[:title]} type="text" label={gettext("Title")} required />

                  <.input
                    field={@form[:description]}
                    type="textarea"
                    label={gettext("Description")}
                    rows="6"
                  />

                  <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <.input field={@form[:event_date]} type="date" label={gettext("Event Date")} />
                    <.input field={@form[:event_time]} type="time" label={gettext("Start Time")} />
                  </div>

                  <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                    <.input field={@form[:end_date]} type="date" label={gettext("End Date")} />
                    <.input field={@form[:end_time]} type="time" label={gettext("End Time")} />
                  </div>

                  <div class="mb-6">
                    <.input
                      field={@form[:timezone]}
                      type="select"
                      label={gettext("Event Timezone")}
                      options={@timezones}
                      prompt={gettext("Select timezone")}
                    />
                    <p class="text-xs text-base-content/60 mt-1">
                      {gettext("The event countdown will be calculated based on this timezone.")}
                    </p>
                  </div>

                  <div class="mb-6">
                    <.input
                      field={@form[:estimated_participants]}
                      type="number"
                      label={gettext("Estimated Participants")}
                      min="1"
                    />
                    <.input
                      field={@form[:online_url]}
                      type="text"
                      label={gettext("Online Link (YouTube)")}
                      placeholder="https://youtube.com/..."
                    />

                    <.input
                      field={@form[:status]}
                      type="select"
                      label={gettext("Status")}
                      options={Event.statuses()}
                    />

                    <div class="flex items-center gap-2 py-2">
                      <.input
                        field={@form[:is_publicly_accessible]}
                        type="checkbox"
                        label={gettext("Feature on Welcome Page (Publicly Accessible)")}
                      />
                    </div>

                    <.input
                      field={@form[:languages]}
                      type="select"
                      label={gettext("Languages")}
                      multiple={true}
                      options={Event.languages()}
                      class="h-32"
                    />

                    <.input
                      field={@form[:level]}
                      type="select"
                      label={gettext("Access Level")}
                      options={["Level1", "Level2", "Level3"]}
                    />
                  </div>

                  <div class="pt-4">
                    <.primary_button type="submit">{gettext("Save Changes")}</.primary_button>
                  </div>
                </div>

                <%!-- Location Tab --%>
                <div :if={@current_tab == "location"} class="space-y-6">
                  <.input field={@form[:venue_name]} type="text" label={gettext("Venue Name")} />

                  <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <.input field={@form[:city]} type="text" label={gettext("City")} />
                    <.input field={@form[:country]} type="text" label={gettext("Country")} />
                  </div>

                  <.input
                    field={@form[:address]}
                    type="textarea"
                    label={gettext("Full Address")}
                    rows="3"
                  />

                  <.input
                    field={@form[:google_maps_link]}
                    type="url"
                    label={gettext("Google Maps Link")}
                    placeholder="https://maps.google.com/..."
                  />

                  <.input
                    field={@form[:google_maps_embed_url]}
                    type="url"
                    label={gettext("Google Maps Embed URL")}
                    placeholder="https://www.google.com/maps/embed?..."
                  />
                  <p class="text-xs text-base-content/50 -mt-4">
                    {gettext(
                      "Get this from Google Maps → Share → Embed a map → Copy the src URL from the iframe"
                    )}
                  </p>

                  <.input
                    field={@form[:venue_website]}
                    type="url"
                    label={gettext("Venue Website")}
                    placeholder="https://..."
                  />

                  <div class="pt-4">
                    <.primary_button type="submit">{gettext("Save Changes")}</.primary_button>
                  </div>
                </div>

                <%!-- Finances Tab --%>
                <div :if={@current_tab == "finances"} class="space-y-6">
                  <h3 class="font-medium text-base-content">{gettext("Budget")}</h3>

                  <.input
                    field={@form[:budget_type]}
                    type="select"
                    label={gettext("Budget Type")}
                    options={[
                      {gettext("Donations"), "open_for_donations"},
                      {gettext("Fixed Budget"), "fixed_budget"}
                    ]}
                  />

                  <.input
                    field={@form[:budget_total]}
                    type="number"
                    label={gettext("Total Budget (€)")}
                    step="0.01"
                    min="0"
                  />

                  <.input
                    field={@form[:budget_notes]}
                    type="textarea"
                    label={gettext("Budget Breakdown/Notes")}
                    rows="4"
                  />

                  <.input
                    field={@form[:resources_required]}
                    type="textarea"
                    label={gettext("Resources Required")}
                    rows="4"
                  />

                  <div class="border-t border-base-content/10 pt-6 mt-6">
                    <h3 class="font-medium text-base-content mb-4">
                      {gettext("Banking Information for Donations")}
                    </h3>

                    <.input
                      field={@form[:banking_name]}
                      type="text"
                      label={gettext("Account Holder Name")}
                    />
                    <.input
                      field={@form[:banking_iban]}
                      type="text"
                      label={gettext("IBAN")}
                      placeholder="RO49AAAA..."
                    />
                    <.input field={@form[:banking_swift]} type="text" label={gettext("SWIFT/BIC")} />
                    <.input
                      field={@form[:banking_notes]}
                      type="textarea"
                      label={gettext("Payment Notes")}
                      rows="3"
                      placeholder={gettext("e.g., Reference code to use when donating")}
                    />
                  </div>

                  <div class="pt-4">
                    <.primary_button type="submit">{gettext("Save Changes")}</.primary_button>
                  </div>
                </div>
              </.form>
            <% end %>

            <%!-- Transportation Tab --%>
            <div :if={@current_tab == "transportation"} class="space-y-6">
              <div class="flex justify-end mb-4">
                <.primary_button type="button" phx-click="add_transport" icon="hero-plus">
                  {gettext("Add Option")}
                </.primary_button>
              </div>

              <%= if @event.transportation_options != [] do %>
                <div class="space-y-3">
                  <h3 class="font-medium text-base-content">
                    {gettext("Public/Bus Transportation")}
                  </h3>
                  <div
                    :for={trans <- @event.transportation_options}
                    class="p-3 bg-base-100/50 rounded-lg border border-base-content/10"
                  >
                    <div class="flex justify-between items-start">
                      <div>
                        <div class="flex items-center gap-2">
                          <span class="font-medium">{trans.title}</span>
                          <span class="text-xs bg-base-200 px-2 py-0.5 rounded uppercase">
                            {trans.transport_type}
                          </span>
                        </div>

                        <%= if trans.transport_type == "car" do %>
                          <div class="text-sm text-base-content/70 mt-1">
                            <span class="font-medium">{trans.driver_name}</span>
                            <%= if trans.driver_phone do %>
                              <span class="text-xs opacity-70">({trans.driver_phone})</span>
                            <% end %>
                            <span class="ml-2">• {trans.capacity} {gettext("seats")}</span>
                          </div>
                        <% end %>

                        <%= if trans.description do %>
                          <p class="text-sm text-base-content/60 mt-1">{trans.description}</p>
                        <% end %>

                        <div class="text-sm mt-1">
                          <%= if trans.departure_location || trans.departure_time do %>
                            <span class="text-base-content/70">
                              {trans.departure_location}
                              {if trans.departure_location && trans.departure_time, do: "•"}
                              {if trans.departure_time,
                                do: Calendar.strftime(trans.departure_time, "%H:%M")}
                            </span>
                          <% end %>
                        </div>
                      </div>

                      <div class="text-right">
                        <%= if trans.pay_at_destination do %>
                          <div class="bg-warning/10 text-warning px-2 py-1 rounded text-xs font-medium">
                            {gettext("Pay at destination")}
                          </div>
                        <% else %>
                          <%= if trans.estimated_cost do %>
                            <span class="font-medium">€{trans.estimated_cost}</span>
                            <span class="text-xs text-base-content/50 block">
                              {gettext("per person")}
                            </span>
                          <% end %>
                        <% end %>
                      </div>
                    </div>

                    <div class="mt-2 flex justify-end">
                      <button
                        type="button"
                        phx-click="delete_transport"
                        phx-value-id={trans.id}
                        class="text-error text-sm hover:underline"
                        data-confirm={gettext("Are you sure?")}
                      >
                        {gettext("Delete")}
                      </button>
                    </div>
                  </div>
                </div>
              <% else %>
                <p class="text-sm text-base-content/50">
                  {gettext("No transportation options added yet.")}
                </p>
              <% end %>

              <%= if @event.carpools != [] do %>
                <div class="mt-6 space-y-3">
                  <h3 class="font-medium text-base-content">{gettext("Carpool Offers")}</h3>
                  <div
                    :for={carpool <- @event.carpools}
                    class="p-3 bg-base-100/50 rounded-lg border border-base-content/10"
                  >
                    <div class="flex justify-between">
                      <span>{carpool.departure_location}</span>
                      <span class="text-sm">{carpool.available_seats} {gettext("seats")}</span>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>

            <%!-- Tasks Tab --%>
            <div :if={@current_tab == "tasks"} class="space-y-6">
              <div class="flex justify-between items-center mb-4">
                <p class="text-base-content/70">
                  {gettext("Manage tasks and assign work.")}
                </p>
                <.primary_button type="button" phx-click="add_task" icon="hero-plus">
                  {gettext("Add Task")}
                </.primary_button>
              </div>

              <%= if @event.tasks != [] do %>
                <div class="space-y-2">
                  <div
                    :for={task <- @event.tasks}
                    class="p-4 bg-base-100/50 rounded-lg border border-base-content/10 flex flex-col sm:flex-row justify-between gap-4"
                  >
                    <div class="space-y-1">
                      <div class="flex items-center gap-2">
                        <span class="font-medium">{task.title}</span>
                        <span class={"px-2 py-0.5 rounded text-xs #{task_status_class(task.status)}"}>
                          {task.status}
                        </span>
                      </div>
                      <%= if task.actual_expense do %>
                        <p class="text-sm">€{Decimal.to_string(task.actual_expense)}</p>
                      <% end %>

                      <%= if task.volunteers != [] do %>
                        <div class="flex flex-wrap gap-1 mt-2">
                          <span class="text-xs text-base-content/60 mr-1">
                            {gettext("Volunteers")}:
                          </span>
                          <span
                            :for={vol <- task.volunteers}
                            class="px-2 py-0.5 bg-primary/10 text-primary rounded-full text-xs"
                          >
                            {vol.email |> String.split("@") |> List.first()}
                          </span>
                        </div>
                      <% end %>
                    </div>

                    <div class="flex gap-2 shrink-0">
                      <button
                        type="button"
                        phx-click="edit_task"
                        phx-value-id={task.id}
                        class="p-2 text-base-content/70 hover:text-primary transition-colors"
                        title={gettext("Edit task")}
                      >
                        <.icon name="hero-pencil-square" class="w-5 h-5" />
                      </button>
                      <button
                        type="button"
                        phx-click="delete_task"
                        phx-value-id={task.id}
                        class="p-2 text-error hover:text-error/80 transition-colors"
                        title={gettext("Delete task")}
                        data-confirm={gettext("Delete task?")}
                      >
                        <.icon name="hero-trash" class="w-5 h-5" />
                      </button>
                    </div>
                  </div>
                </div>
              <% else %>
                <p class="text-sm text-base-content/50">{gettext("No tasks added yet.")}</p>
              <% end %>
            </div>

            <%!-- Team Tab --%>
            <div :if={@current_tab == "team"} class="space-y-6">
              <div class="mb-6">
                <h3 class="font-medium text-base-content mb-4">{gettext("Add Co-Owner")}</h3>
                <form phx-submit="invite_collaborator" class="flex gap-2">
                  <input
                    type="email"
                    name="email"
                    value={@invite_email}
                    placeholder={gettext("Enter user email")}
                    class="input input-bordered w-full max-w-sm"
                    required
                  />
                  <.primary_button type="submit" icon="hero-user-plus">
                    {gettext("Invite")}
                  </.primary_button>
                </form>
                <p class="text-sm text-base-content/60 mt-2">
                  {gettext("The user must already have an account on the platform.")}
                </p>
              </div>

              <div class="space-y-3">
                <h3 class="font-medium text-base-content">{gettext("Team Members")}</h3>
                <%= if @event.team_members != [] do %>
                  <div class="space-y-2">
                    <div
                      :for={member <- @event.team_members}
                      class="p-4 bg-base-100/50 rounded-lg border border-base-content/10 flex justify-between items-center"
                    >
                      <div>
                        <div class="font-medium">{member.user.email}</div>
                        <div class="text-sm text-base-content/60">
                          {String.capitalize(member.role)} •
                          <span class={
                            if member.status == "accepted", do: "text-success", else: "text-warning"
                          }>
                            {String.capitalize(member.status)}
                          </span>
                        </div>
                      </div>
                      <%= if member.user_id != @current_scope.user.id do %>
                        <button
                          type="button"
                          phx-click="remove_collaborator"
                          phx-value-id={member.id}
                          class="text-error hover:text-error/80 text-sm font-medium"
                          data-confirm={gettext("Remove this team member?")}
                        >
                          {gettext("Remove")}
                        </button>
                      <% end %>
                    </div>
                  </div>
                <% else %>
                  <p class="text-sm text-base-content/50">{gettext("No team members yet.")}</p>
                <% end %>
              </div>
            </div>
          </.card>
        </div>
      </.page_container>
    </Layouts.app>
    """
  end

  defp task_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
      <div class="bg-base-100 rounded-xl shadow-xl w-full max-w-lg p-6 animate-in fade-in zoom-in duration-200">
        <h3 class="text-lg font-bold mb-4">
          {if @form.data.id, do: gettext("Edit Task"), else: gettext("Add New Task")}
        </h3>

        <.form for={@form} phx-change="validate_task" phx-submit="save_task">
          <div class="space-y-4">
            <.input field={@form[:title]} type="text" label={gettext("Task Title")} required />
            <.input field={@form[:description]} type="textarea" label={gettext("Description")} />
            <div class="grid grid-cols-2 gap-4">
              <.input
                field={@form[:status]}
                type="select"
                label={gettext("Status")}
                options={EventTask.statuses()}
              />
              <.input field={@form[:due_date]} type="date" label={gettext("Due Date")} />
            </div>
            <div class="grid grid-cols-2 gap-4">
              <.input
                field={@form[:city]}
                type="text"
                label={gettext("City")}
                placeholder="e.g. London"
              />
              <.input
                field={@form[:country]}
                type="text"
                label={gettext("Country")}
                placeholder="e.g. UK"
              />
            </div>
            <div class="grid grid-cols-2 gap-4">
              <.input field={@form[:start_date]} type="date" label={gettext("Start Date")} />
            </div>
            <div class="grid grid-cols-2 gap-4">
              <.input
                field={@form[:estimated_expense]}
                type="number"
                step="0.01"
                label={gettext("Est. Expense")}
              />
              <.input
                field={@form[:actual_expense]}
                type="number"
                step="0.01"
                label={gettext("Actual Expense")}
              />
            </div>
          </div>
          <div class="flex justify-end gap-2 mt-6">
            <.secondary_button type="button" phx-click="cancel_task_modal">
              {gettext("Cancel")}
            </.secondary_button>
            <.primary_button type="submit">{gettext("Save Task")}</.primary_button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  defp transport_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
      <div class="bg-base-100 rounded-xl shadow-xl w-full max-w-lg p-6 animate-in fade-in zoom-in duration-200 overflow-y-auto max-h-[90vh]">
        <h3 class="text-lg font-bold mb-4">{gettext("Add Transportation Option")}</h3>

        <.form for={@form} phx-change="validate_transport" phx-submit="save_transport">
          <div class="space-y-4">
            <.input
              field={@form[:title]}
              type="text"
              label={gettext("Title")}
              placeholder="e.g. Bus from Central Station"
              required
            />
            <.input
              field={@form[:transport_type]}
              type="select"
              label={gettext("Type")}
              options={EventTransportation.transport_types()}
            />

            <.input field={@form[:description]} type="textarea" label={gettext("Description")} />
            <div class="grid grid-cols-2 gap-4">
              <.input
                field={@form[:departure_location]}
                type="text"
                label={gettext("Departure Location")}
              />
              <.input field={@form[:departure_time]} type="time" label={gettext("Departure Time")} />
            </div>

            <div class="space-y-2">
              <.input
                field={@form[:pay_at_destination]}
                type="checkbox"
                label={gettext("Pay at Destination / Flexible Cost")}
              />

              <%= if @form[:pay_at_destination].value != true do %>
                <.input
                  field={@form[:estimated_cost]}
                  type="number"
                  step="0.01"
                  label={gettext("Est. Cost per person")}
                />
              <% end %>
            </div>
          </div>
          <div class="flex justify-end gap-2 mt-6">
            <.secondary_button type="button" phx-click="cancel_transport_modal">
              {gettext("Cancel")}
            </.secondary_button>
            <.primary_button type="submit">{gettext("Save Option")}</.primary_button>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end

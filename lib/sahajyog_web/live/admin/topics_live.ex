defmodule SahajyogWeb.Admin.TopicsLive do
  use SahajyogWeb, :live_view

  import SahajyogWeb.AdminNav

  alias Sahajyog.Topics

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Manage Topics")
     |> assign(:topics, Topics.list_topics())
     |> assign(:filter, "all")
     |> assign(:viewing_topic, nil)
     |> assign(:co_authors, [])
     |> assign(:all_users, Sahajyog.Accounts.list_users())
     |> assign(:invite_user_id, nil)}
  end

  @impl true
  def handle_event("filter", %{"status" => status}, socket) do
    topics =
      if status == "all" do
        Topics.list_topics()
      else
        Topics.list_topics(%{status: status})
      end

    {:noreply,
     socket
     |> assign(:topics, topics)
     |> assign(:filter, status)}
  end

  @impl true
  def handle_event("view_details", %{"id" => id}, socket) do
    topic = Topics.get_topic!(String.to_integer(id))
    co_authors = Topics.list_co_authors(topic.id)

    {:noreply,
     socket
     |> assign(:viewing_topic, topic)
     |> assign(:co_authors, co_authors)}
  end

  @impl true
  def handle_event("close_details", _, socket) do
    {:noreply,
     socket
     |> assign(:viewing_topic, nil)
     |> assign(:co_authors, [])
     |> assign(:invite_user_id, nil)}
  end

  @impl true
  def handle_event("invite_co_author", %{"user_id" => user_id}, socket) do
    topic = socket.assigns.viewing_topic

    case Topics.invite_co_author(
           socket.assigns.current_scope,
           topic.id,
           String.to_integer(user_id)
         ) do
      {:ok, _co_author} ->
        {:noreply,
         socket
         |> assign(:co_authors, Topics.list_co_authors(topic.id))
         |> assign(:invite_user_id, nil)
         |> put_flash(:info, gettext("Co-author invitation sent"))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to invite co-author"))}
    end
  end

  @impl true
  def handle_event("remove_co_author", %{"id" => id}, socket) do
    co_author = Enum.find(socket.assigns.co_authors, &(&1.id == String.to_integer(id)))
    {:ok, _} = Topics.remove_co_author(co_author)

    {:noreply,
     socket
     |> assign(:co_authors, Topics.list_co_authors(socket.assigns.viewing_topic.id))
     |> put_flash(:info, gettext("Co-author removed"))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    topic = Topics.get_topic!(String.to_integer(id))
    {:ok, _} = Topics.delete_topic(topic)

    {:noreply,
     socket
     |> assign(:topics, Topics.list_topics())
     |> put_flash(:info, gettext("Topic deleted successfully"))}
  end

  defp filter_options do
    [
      {"all", gettext("All"), "hero-squares-2x2"},
      {"draft", gettext("Draft"), "hero-pencil"},
      {"published", gettext("Published"), "hero-check-circle"},
      {"archived", gettext("Archived"), "hero-archive-box"}
    ]
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_container>
      <.admin_nav current_page={:topics} />

      <div class="max-w-7xl mx-auto px-4 py-8">
        <.page_header title={gettext("Manage Topics")} />

        <%!-- Filter Tabs --%>
        <.filter_tabs
          options={filter_options()}
          selected={@filter}
          on_select="filter"
          param_name="status"
        />

        <%!-- Topics List --%>
        <%= if @topics == [] do %>
          <.card>
            <.empty_state
              icon="hero-document-text"
              title={gettext("No topics found")}
              description={gettext("No topics match the selected filter")}
            />
          </.card>
        <% else %>
          <%!-- Mobile Card View --%>
          <div class="block lg:hidden space-y-4">
            <.card :for={topic <- @topics} size="sm" class="p-4">
              <div class="flex items-start justify-between gap-3 mb-3">
                <div class="flex-1 min-w-0">
                  <h3 class="text-base font-bold text-base-content mb-1 line-clamp-2">
                    {topic.title}
                  </h3>
                  <p class="text-xs text-base-content/60 truncate">/{topic.slug}</p>
                </div>
                <.status_badge status={topic.status} size="sm" />
              </div>

              <div class="flex items-center gap-4 text-xs text-base-content/50 mb-3">
                <span class="flex items-center gap-1 truncate">
                  <.icon name="hero-user" class="w-3 h-3 flex-shrink-0" />
                  <span class="truncate">{topic.user.email}</span>
                </span>
                <span class="flex items-center gap-1">
                  <.icon name="hero-eye" class="w-3 h-3" />
                  {topic.views_count}
                </span>
              </div>

              <div class="grid grid-cols-2 gap-2">
                <button
                  phx-click="view_details"
                  phx-value-id={topic.id}
                  class="px-3 py-2 bg-base-200 text-secondary rounded-lg hover:bg-secondary hover:text-secondary-content transition-colors text-xs font-semibold focus:outline-none focus:ring-2 focus:ring-secondary"
                >
                  {gettext("Details")}
                </button>
                <.link
                  navigate={~p"/topics/#{topic.slug}"}
                  class="px-3 py-2 bg-primary text-primary-content rounded-lg hover:bg-primary/90 transition-colors text-xs font-semibold text-center focus:outline-none focus:ring-2 focus:ring-primary"
                >
                  {gettext("View")}
                </.link>
                <.link
                  navigate={~p"/topics/#{topic.slug}/edit"}
                  class="px-3 py-2 bg-base-200 text-warning rounded-lg hover:bg-warning hover:text-warning-content transition-colors text-xs font-semibold text-center focus:outline-none focus:ring-2 focus:ring-warning"
                >
                  {gettext("Edit")}
                </.link>
                <button
                  phx-click="delete"
                  phx-value-id={topic.id}
                  data-confirm={gettext("Are you sure?")}
                  class="px-3 py-2 bg-base-200 text-error rounded-lg hover:bg-error/20 transition-colors text-xs font-semibold focus:outline-none focus:ring-2 focus:ring-error/50"
                >
                  {gettext("Delete")}
                </button>
              </div>
            </.card>
          </div>

          <%!-- Desktop Table View --%>
          <div class="hidden lg:block">
            <.card class="overflow-hidden p-0">
              <table class="min-w-full divide-y divide-base-content/10">
                <thead class="bg-base-300">
                  <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-base-content/70 uppercase">
                      {gettext("Title")}
                    </th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-base-content/70 uppercase">
                      {gettext("Author")}
                    </th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-base-content/70 uppercase">
                      {gettext("Status")}
                    </th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-base-content/70 uppercase">
                      {gettext("Views")}
                    </th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-base-content/70 uppercase">
                      {gettext("Published")}
                    </th>
                    <th class="px-6 py-3 text-right text-xs font-medium text-base-content/70 uppercase">
                      {gettext("Actions")}
                    </th>
                  </tr>
                </thead>
                <tbody class="bg-base-200 divide-y divide-base-content/10">
                  <tr :for={topic <- @topics} class="hover:bg-base-100 transition-colors">
                    <td class="px-6 py-4">
                      <div class="text-sm font-medium text-base-content">{topic.title}</div>
                      <div class="text-xs text-base-content/60 mt-1">/{topic.slug}</div>
                    </td>
                    <td class="px-6 py-4 text-sm text-base-content/80">
                      {topic.user.email}
                    </td>
                    <td class="px-6 py-4">
                      <.status_badge status={topic.status} size="sm" />
                    </td>
                    <td class="px-6 py-4 text-sm text-base-content/80">
                      {topic.views_count}
                    </td>
                    <td class="px-6 py-4 text-sm text-base-content/80">
                      <%= if topic.published_at do %>
                        {Calendar.strftime(topic.published_at, "%b %d, %Y")}
                      <% else %>
                        <span class="text-base-content/50">-</span>
                      <% end %>
                    </td>
                    <td class="px-6 py-4 text-right text-sm font-medium">
                      <div class="flex justify-end gap-3">
                        <button
                          phx-click="view_details"
                          phx-value-id={topic.id}
                          class="text-secondary hover:text-secondary/80 focus:outline-none focus:ring-2 focus:ring-secondary rounded"
                        >
                          {gettext("Details")}
                        </button>
                        <.link
                          navigate={~p"/topics/#{topic.slug}"}
                          class="text-primary hover:text-primary/80 focus:outline-none focus:ring-2 focus:ring-primary rounded"
                        >
                          {gettext("View")}
                        </.link>
                        <.link
                          navigate={~p"/topics/#{topic.slug}/edit"}
                          class="text-warning hover:text-warning/80 focus:outline-none focus:ring-2 focus:ring-warning rounded"
                        >
                          {gettext("Edit")}
                        </.link>
                        <button
                          phx-click="delete"
                          phx-value-id={topic.id}
                          data-confirm={gettext("Are you sure?")}
                          class="text-error/70 hover:text-error focus:outline-none focus:ring-2 focus:ring-error/50 rounded"
                        >
                          {gettext("Delete")}
                        </button>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </.card>
          </div>
        <% end %>

        <%!-- Topic Details Modal --%>
        <.modal :if={@viewing_topic} id="topic-details-modal" on_close="close_details" size="lg">
          <:title>{gettext("Topic Details")}</:title>

          <%!-- Topic Info --%>
          <div class="mb-6 p-4 bg-base-100/50 rounded-lg border border-base-content/10">
            <h3 class="font-semibold text-base-content text-lg mb-3">{@viewing_topic.title}</h3>
            <div class="space-y-2 text-sm">
              <div class="flex items-center gap-2 text-base-content/60">
                <.icon name="hero-user" class="w-4 h-4" />
                <span class="font-semibold">{gettext("Author")}:</span>
                <span class="text-base-content">{@viewing_topic.user.email}</span>
              </div>
              <div class="flex items-center gap-2 text-base-content/60">
                <.icon name="hero-tag" class="w-4 h-4" />
                <span class="font-semibold">{gettext("Status")}:</span>
                <.status_badge status={@viewing_topic.status} size="sm" />
              </div>
              <div class="flex items-center gap-2 text-base-content/60">
                <.icon name="hero-eye" class="w-4 h-4" />
                <span class="font-semibold">{gettext("Views")}:</span>
                <span class="text-base-content">{@viewing_topic.views_count}</span>
              </div>
              <%= if @viewing_topic.published_at do %>
                <div class="flex items-center gap-2 text-base-content/60">
                  <.icon name="hero-calendar" class="w-4 h-4" />
                  <span class="font-semibold">{gettext("Published")}:</span>
                  <span class="text-base-content">
                    {Calendar.strftime(@viewing_topic.published_at, "%B %d, %Y")}
                  </span>
                </div>
              <% end %>
            </div>
          </div>

          <%!-- Co-Authors Section --%>
          <div class="mb-6">
            <h3 class="text-lg font-semibold text-base-content mb-4">
              {gettext("Co-Authors")}
            </h3>

            <%!-- Existing Co-Authors --%>
            <%= if @co_authors == [] do %>
              <p class="text-base-content/50 text-sm mb-4">{gettext("No co-authors yet")}</p>
            <% else %>
              <div class="space-y-2 mb-4">
                <div
                  :for={co_author <- @co_authors}
                  class="flex items-center justify-between p-3 bg-base-100/50 rounded-lg border border-base-content/10"
                >
                  <div class="flex items-center gap-3">
                    <div class="flex items-center justify-center w-8 h-8 rounded-full bg-base-200 text-base-content text-xs font-semibold">
                      {String.upcase(String.first(co_author.user.email))}
                    </div>
                    <div>
                      <p class="text-sm text-base-content">{co_author.user.email}</p>
                      <p class="text-xs text-base-content/60">
                        {gettext("Status")}:
                        <span class={[
                          "font-semibold",
                          co_author.status == "pending" && "text-warning",
                          co_author.status == "accepted" && "text-success",
                          co_author.status == "rejected" && "text-error"
                        ]}>
                          {co_author.status}
                        </span>
                      </p>
                    </div>
                  </div>
                  <button
                    phx-click="remove_co_author"
                    phx-value-id={co_author.id}
                    data-confirm={gettext("Remove this co-author?")}
                    class="text-error hover:text-error/80 text-sm focus:outline-none focus:ring-2 focus:ring-error rounded"
                  >
                    {gettext("Remove")}
                  </button>
                </div>
              </div>
            <% end %>

            <%!-- Add Co-Author --%>
            <div class="p-4 bg-base-100/30 rounded-lg border border-base-content/10">
              <label class="block text-sm font-medium text-base-content/80 mb-2">
                {gettext("Invite Co-Author")}
              </label>
              <div class="flex gap-2">
                <select
                  class="flex-1 px-3 py-2 bg-base-200 border border-base-content/20 rounded-lg text-base-content text-sm focus:outline-none focus:ring-2 focus:ring-primary"
                  phx-change="invite_co_author"
                  name="user_id"
                >
                  <option value="">{gettext("Select a user...")}</option>
                  <%= for user <- @all_users do %>
                    <%= if user.id != @viewing_topic.user_id && !Enum.any?(@co_authors, &(&1.user_id == user.id)) do %>
                      <option value={user.id}>{user.email}</option>
                    <% end %>
                  <% end %>
                </select>
              </div>
              <p class="text-xs text-base-content/50 mt-2">
                {gettext("Select a user to invite them as a co-author")}
              </p>
            </div>
          </div>

          <:footer>
            <.primary_button navigate={~p"/topics/#{@viewing_topic.slug}/edit"}>
              {gettext("Edit Topic")}
            </.primary_button>
            <.secondary_button phx-click="close_details">
              {gettext("Close")}
            </.secondary_button>
          </:footer>
        </.modal>
      </div>
    </.page_container>
    """
  end
end

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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900">
      <.admin_nav current_page={:topics} />

      <div class="max-w-7xl mx-auto px-4 py-8">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
          <h1 class="text-3xl sm:text-4xl font-bold text-white">
            {gettext("Manage Topics")}
          </h1>
        </div>

        <%!-- Filter Tabs --%>
        <div class="mb-6 sm:mb-8">
          <div class="bg-gradient-to-br from-gray-800/80 to-gray-900/80 backdrop-blur-sm rounded-xl p-2 border border-gray-700/50 shadow-xl inline-flex flex-wrap gap-2 w-full sm:w-auto">
            <button
              phx-click="filter"
              phx-value-status="all"
              class={[
                "px-4 py-2.5 rounded-lg transition-all duration-200 font-semibold text-sm sm:text-base flex items-center gap-2",
                if(@filter == "all",
                  do: "bg-gray-700 text-white border-2 border-white",
                  else:
                    "bg-gray-700/50 text-gray-300 hover:bg-gray-700 hover:text-white border-2 border-transparent"
                )
              ]}
            >
              <.icon name="hero-squares-2x2" class="w-4 h-4" />
              {gettext("All")}
            </button>
            <button
              phx-click="filter"
              phx-value-status="draft"
              class={[
                "px-4 py-2.5 rounded-lg transition-all duration-200 font-semibold text-sm sm:text-base flex items-center gap-2",
                if(@filter == "draft",
                  do: "bg-gray-700 text-white border-2 border-white",
                  else:
                    "bg-gray-700/50 text-gray-300 hover:bg-gray-700 hover:text-white border-2 border-transparent"
                )
              ]}
            >
              <.icon name="hero-pencil" class="w-4 h-4" />
              {gettext("Draft")}
            </button>
            <button
              phx-click="filter"
              phx-value-status="published"
              class={[
                "px-4 py-2.5 rounded-lg transition-all duration-200 font-semibold text-sm sm:text-base flex items-center gap-2",
                if(@filter == "published",
                  do: "bg-gray-700 text-white border-2 border-white",
                  else:
                    "bg-gray-700/50 text-gray-300 hover:bg-gray-700 hover:text-white border-2 border-transparent"
                )
              ]}
            >
              <.icon name="hero-check-circle" class="w-4 h-4" />
              {gettext("Published")}
            </button>
            <button
              phx-click="filter"
              phx-value-status="archived"
              class={[
                "px-4 py-2.5 rounded-lg transition-all duration-200 font-semibold text-sm sm:text-base flex items-center gap-2",
                if(@filter == "archived",
                  do: "bg-gray-700 text-white border-2 border-white",
                  else:
                    "bg-gray-700/50 text-gray-300 hover:bg-gray-700 hover:text-white border-2 border-transparent"
                )
              ]}
            >
              <.icon name="hero-archive-box" class="w-4 h-4" />
              {gettext("Archived")}
            </button>
          </div>
        </div>

        <%!-- Topics List --%>
        <%= if @topics == [] do %>
          <div class="text-center py-16 bg-gray-800 rounded-xl border border-gray-700">
            <div class="inline-flex items-center justify-center w-20 h-20 rounded-full bg-gray-700 border border-gray-600 mb-4">
              <.icon name="hero-document-text" class="w-10 h-10 text-gray-500" />
            </div>
            <h3 class="text-xl font-semibold text-gray-300 mb-2">
              {gettext("No topics found")}
            </h3>
            <p class="text-gray-500">{gettext("No topics match the selected filter")}</p>
          </div>
        <% else %>
          <%!-- Mobile Card View --%>
          <div class="block lg:hidden space-y-4">
            <div
              :for={topic <- @topics}
              class="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-4 border border-gray-700/50"
            >
              <div class="flex items-start justify-between gap-3 mb-3">
                <div class="flex-1 min-w-0">
                  <h3 class="text-base font-bold text-white mb-1 line-clamp-2">{topic.title}</h3>
                  <p class="text-xs text-gray-400 truncate">/{topic.slug}</p>
                </div>
                <span class={[
                  "px-2 py-1 rounded-full text-xs font-semibold whitespace-nowrap",
                  topic.status == "draft" &&
                    "bg-yellow-500/10 text-yellow-400 border border-yellow-500/20",
                  topic.status == "published" &&
                    "bg-green-500/10 text-green-400 border border-green-500/20",
                  topic.status == "archived" &&
                    "bg-gray-500/10 text-gray-400 border border-gray-500/20"
                ]}>
                  {topic.status}
                </span>
              </div>

              <div class="flex items-center gap-4 text-xs text-gray-500 mb-3">
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
                  class="px-3 py-2 bg-gray-700 text-purple-400 rounded-lg hover:bg-purple-600 hover:text-white transition-colors text-xs font-semibold"
                >
                  {gettext("Details")}
                </button>
                <.link
                  navigate={~p"/topics/#{topic.slug}"}
                  class="px-3 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-xs font-semibold text-center"
                >
                  {gettext("View")}
                </.link>
                <.link
                  navigate={~p"/topics/#{topic.slug}/edit"}
                  class="px-3 py-2 bg-gray-700 text-orange-400 rounded-lg hover:bg-orange-600 hover:text-white transition-colors text-xs font-semibold text-center"
                >
                  {gettext("Edit")}
                </.link>
                <button
                  phx-click="delete"
                  phx-value-id={topic.id}
                  data-confirm={gettext("Are you sure?")}
                  class="px-3 py-2 bg-gray-700 text-red-400 rounded-lg hover:bg-red-600 hover:text-white transition-colors text-xs font-semibold"
                >
                  {gettext("Delete")}
                </button>
              </div>
            </div>
          </div>

          <%!-- Desktop Table View --%>
          <div class="hidden lg:block bg-gray-800 rounded-xl shadow-lg overflow-hidden border border-gray-700">
            <table class="min-w-full divide-y divide-gray-700">
              <thead class="bg-gray-900">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase">
                    {gettext("Title")}
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase">
                    {gettext("Author")}
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase">
                    {gettext("Status")}
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase">
                    {gettext("Views")}
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase">
                    {gettext("Published")}
                  </th>
                  <th class="px-6 py-3 text-right text-xs font-medium text-gray-300 uppercase">
                    {gettext("Actions")}
                  </th>
                </tr>
              </thead>
              <tbody class="bg-gray-800 divide-y divide-gray-700">
                <tr :for={topic <- @topics} class="hover:bg-gray-700 transition-colors">
                  <td class="px-6 py-4">
                    <div class="text-sm font-medium text-white">{topic.title}</div>
                    <div class="text-xs text-gray-400 mt-1">/{topic.slug}</div>
                  </td>
                  <td class="px-6 py-4 text-sm text-gray-300">
                    {topic.user.email}
                  </td>
                  <td class="px-6 py-4">
                    <span class={[
                      "px-2 py-1 rounded-full text-xs font-semibold",
                      topic.status == "draft" &&
                        "bg-yellow-500/10 text-yellow-400 border border-yellow-500/20",
                      topic.status == "published" &&
                        "bg-green-500/10 text-green-400 border border-green-500/20",
                      topic.status == "archived" &&
                        "bg-gray-500/10 text-gray-400 border border-gray-500/20"
                    ]}>
                      {topic.status}
                    </span>
                  </td>
                  <td class="px-6 py-4 text-sm text-gray-300">
                    {topic.views_count}
                  </td>
                  <td class="px-6 py-4 text-sm text-gray-300">
                    <%= if topic.published_at do %>
                      {Calendar.strftime(topic.published_at, "%b %d, %Y")}
                    <% else %>
                      <span class="text-gray-500">-</span>
                    <% end %>
                  </td>
                  <td class="px-6 py-4 text-right text-sm font-medium">
                    <div class="flex justify-end gap-3">
                      <button
                        phx-click="view_details"
                        phx-value-id={topic.id}
                        class="text-purple-400 hover:text-purple-300"
                      >
                        {gettext("Details")}
                      </button>
                      <.link
                        navigate={~p"/topics/#{topic.slug}"}
                        class="text-blue-400 hover:text-blue-300"
                      >
                        {gettext("View")}
                      </.link>
                      <.link
                        navigate={~p"/topics/#{topic.slug}/edit"}
                        class="text-orange-400 hover:text-orange-300"
                      >
                        {gettext("Edit")}
                      </.link>
                      <button
                        phx-click="delete"
                        phx-value-id={topic.id}
                        data-confirm={gettext("Are you sure?")}
                        class="text-red-400 hover:text-red-300"
                      >
                        {gettext("Delete")}
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        <% end %>

        <%!-- Topic Details Modal --%>
        <%= if @viewing_topic do %>
          <div class="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
            <div class="bg-gradient-to-br from-gray-800 to-gray-900 rounded-2xl max-w-3xl w-full max-h-[90vh] overflow-auto border border-gray-700/50 shadow-2xl">
              <div class="p-6">
                <div class="flex items-center justify-between mb-6">
                  <h2 class="text-2xl font-bold text-white">
                    {gettext("Topic Details")}
                  </h2>
                  <button
                    phx-click="close_details"
                    class="p-2 text-gray-400 hover:text-white hover:bg-gray-700 rounded-lg transition-all"
                  >
                    <.icon name="hero-x-mark" class="w-6 h-6" />
                  </button>
                </div>

                <%!-- Topic Info --%>
                <div class="mb-6 p-4 bg-gray-700/30 rounded-lg border border-gray-700/50">
                  <h3 class="font-semibold text-white text-lg mb-3">{@viewing_topic.title}</h3>
                  <div class="space-y-2 text-sm">
                    <div class="flex items-center gap-2 text-gray-400">
                      <.icon name="hero-user" class="w-4 h-4" />
                      <span class="font-semibold">{gettext("Author")}:</span>
                      <span class="text-white">{@viewing_topic.user.email}</span>
                    </div>
                    <div class="flex items-center gap-2 text-gray-400">
                      <.icon name="hero-tag" class="w-4 h-4" />
                      <span class="font-semibold">{gettext("Status")}:</span>
                      <span class={[
                        "px-2 py-0.5 rounded-full text-xs font-semibold",
                        @viewing_topic.status == "draft" &&
                          "bg-yellow-500/10 text-yellow-400 border border-yellow-500/20",
                        @viewing_topic.status == "published" &&
                          "bg-green-500/10 text-green-400 border border-green-500/20",
                        @viewing_topic.status == "archived" &&
                          "bg-gray-500/10 text-gray-400 border border-gray-500/20"
                      ]}>
                        {@viewing_topic.status}
                      </span>
                    </div>
                    <div class="flex items-center gap-2 text-gray-400">
                      <.icon name="hero-eye" class="w-4 h-4" />
                      <span class="font-semibold">{gettext("Views")}:</span>
                      <span class="text-white">{@viewing_topic.views_count}</span>
                    </div>
                    <%= if @viewing_topic.published_at do %>
                      <div class="flex items-center gap-2 text-gray-400">
                        <.icon name="hero-calendar" class="w-4 h-4" />
                        <span class="font-semibold">{gettext("Published")}:</span>
                        <span class="text-white">
                          {Calendar.strftime(@viewing_topic.published_at, "%B %d, %Y")}
                        </span>
                      </div>
                    <% end %>
                  </div>
                </div>

                <%!-- Co-Authors Section --%>
                <div class="mb-6">
                  <h3 class="text-lg font-semibold text-white mb-4">
                    {gettext("Co-Authors")}
                  </h3>

                  <%!-- Existing Co-Authors --%>
                  <%= if @co_authors == [] do %>
                    <p class="text-gray-500 text-sm mb-4">{gettext("No co-authors yet")}</p>
                  <% else %>
                    <div class="space-y-2 mb-4">
                      <div
                        :for={co_author <- @co_authors}
                        class="flex items-center justify-between p-3 bg-gray-700/30 rounded-lg border border-gray-700/50"
                      >
                        <div class="flex items-center gap-3">
                          <div class="flex items-center justify-center w-8 h-8 rounded-full bg-gray-600 text-white text-xs font-semibold">
                            {String.upcase(String.first(co_author.user.email))}
                          </div>
                          <div>
                            <p class="text-sm text-white">{co_author.user.email}</p>
                            <p class="text-xs text-gray-400">
                              {gettext("Status")}:
                              <span class={[
                                "font-semibold",
                                co_author.status == "pending" && "text-yellow-400",
                                co_author.status == "accepted" && "text-green-400",
                                co_author.status == "rejected" && "text-red-400"
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
                          class="text-red-400 hover:text-red-300 text-sm"
                        >
                          {gettext("Remove")}
                        </button>
                      </div>
                    </div>
                  <% end %>

                  <%!-- Add Co-Author --%>
                  <div class="p-4 bg-gray-700/20 rounded-lg border border-gray-700/50">
                    <label class="block text-sm font-medium text-gray-300 mb-2">
                      {gettext("Invite Co-Author")}
                    </label>
                    <div class="flex gap-2">
                      <select
                        class="flex-1 px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:ring-2 focus:ring-orange-500"
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
                    <p class="text-xs text-gray-400 mt-2">
                      {gettext("Select a user to invite them as a co-author")}
                    </p>
                  </div>
                </div>

                <%!-- Actions --%>
                <div class="flex gap-3 pt-4 border-t border-gray-700/50">
                  <.link
                    navigate={~p"/topics/#{@viewing_topic.slug}/edit"}
                    class="px-6 py-3 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors font-semibold"
                  >
                    {gettext("Edit Topic")}
                  </.link>
                  <button
                    phx-click="close_details"
                    class="px-6 py-3 bg-gray-700 text-white rounded-lg hover:bg-gray-600 transition-colors font-semibold"
                  >
                    {gettext("Close")}
                  </button>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end

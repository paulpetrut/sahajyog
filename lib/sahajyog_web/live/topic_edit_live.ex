defmodule SahajyogWeb.TopicEditLive do
  use SahajyogWeb, :live_view

  import SahajyogWeb.QuillEditor

  alias Sahajyog.Topics
  alias Sahajyog.Topics.{Topic, TopicReference}

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    topic = Topics.get_topic_by_slug!(slug)

    if Topics.can_edit_topic?(socket.assigns.current_scope, topic) do
      changeset = Topics.change_topic(topic)
      references = Topics.list_references(topic.id)

      # Get available resources for referencing
      user = socket.assigns.current_scope.user
      available_resources = Sahajyog.Resources.list_resources_for_user(user)

      {:ok,
       socket
       |> assign(:page_title, "Edit Topic")
       |> assign(:topic, topic)
       |> assign(:form, to_form(changeset))
       |> assign(:references, references)
       |> assign(:editing_reference, nil)
       |> assign(:reference_form, nil)
       |> assign(:available_resources, available_resources)}
    else
      {:ok,
       socket
       |> put_flash(:error, gettext("You don't have permission to edit this topic"))
       |> push_navigate(to: ~p"/topics/#{topic.slug}")}
    end
  end

  @impl true
  def handle_event("validate", %{"topic" => topic_params}, socket) do
    changeset =
      socket.assigns.topic
      |> Topics.change_topic(topic_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"topic" => topic_params}, socket) do
    case Topics.update_topic(socket.assigns.topic, topic_params) do
      {:ok, topic} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Topic updated successfully"))
         |> push_navigate(to: ~p"/topics/#{topic.slug}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("add_reference", _, socket) do
    reference = %TopicReference{topic_id: socket.assigns.topic.id}
    changeset = Topics.change_reference(reference)

    {:noreply,
     socket
     |> assign(:editing_reference, :new)
     |> assign(:reference_form, to_form(changeset))}
  end

  @impl true
  def handle_event("edit_reference", %{"id" => id}, socket) do
    reference = Enum.find(socket.assigns.references, &(&1.id == String.to_integer(id)))
    changeset = Topics.change_reference(reference)

    {:noreply,
     socket
     |> assign(:editing_reference, reference)
     |> assign(:reference_form, to_form(changeset))}
  end

  @impl true
  def handle_event("cancel_reference", _, socket) do
    {:noreply,
     socket
     |> assign(:editing_reference, nil)
     |> assign(:reference_form, nil)}
  end

  @impl true
  def handle_event("validate_reference", %{"topic_reference" => ref_params}, socket) do
    reference = socket.assigns.editing_reference

    changeset =
      if reference == :new do
        %TopicReference{topic_id: socket.assigns.topic.id}
        |> Topics.change_reference(ref_params)
      else
        reference
        |> Topics.change_reference(ref_params)
      end
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :reference_form, to_form(changeset))}
  end

  @impl true
  def handle_event("save_reference", %{"topic_reference" => ref_params}, socket) do
    ref_params = Map.put(ref_params, "topic_id", socket.assigns.topic.id)

    result =
      if socket.assigns.editing_reference == :new do
        Topics.create_reference(ref_params)
      else
        Topics.update_reference(socket.assigns.editing_reference, ref_params)
      end

    case result do
      {:ok, _reference} ->
        {:noreply,
         socket
         |> assign(:references, Topics.list_references(socket.assigns.topic.id))
         |> assign(:editing_reference, nil)
         |> assign(:reference_form, nil)
         |> put_flash(:info, gettext("Reference saved"))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :reference_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("select_resource", %{"resource_id" => ""}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_resource", %{"resource_id" => resource_id}, socket) do
    resource = Sahajyog.Resources.get_resource!(String.to_integer(resource_id))

    # Map resource type to reference type
    reference_type =
      case resource.resource_type do
        "Books" -> "book"
        "Photos" -> "article"
        "Music" -> "article"
        _ -> "article"
      end

    # Generate preview URL with resource ID as query parameter
    preview_url = url(~p"/resources?preview=#{resource.id}")

    # Create a new reference with pre-filled data
    reference = %TopicReference{
      topic_id: socket.assigns.topic.id,
      reference_type: reference_type,
      title: resource.title,
      url: preview_url,
      description: resource.description || "Available in Resources section"
    }

    changeset = Topics.change_reference(reference)

    {:noreply,
     socket
     |> assign(:editing_reference, :new)
     |> assign(:reference_form, to_form(changeset))
     |> put_flash(:info, gettext("Resource details loaded. Review and save."))}
  end

  @impl true
  def handle_event("delete_reference", %{"id" => id}, socket) do
    reference = Enum.find(socket.assigns.references, &(&1.id == String.to_integer(id)))
    {:ok, _} = Topics.delete_reference(reference)

    {:noreply,
     socket
     |> assign(:references, Topics.list_references(socket.assigns.topic.id))
     |> put_flash(:info, gettext("Reference deleted"))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900">
      <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <%!-- Back Button --%>
        <.link
          navigate={~p"/topics/#{@topic.slug}"}
          class="text-blue-400 hover:text-blue-300 mb-6 inline-flex items-center gap-2"
        >
          <.icon name="hero-arrow-left" class="w-4 h-4" />
          {gettext("Back to Topic")}
        </.link>

        <%!-- Topic Form --%>
        <div class="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-4 sm:p-6 lg:p-8 border border-gray-700/50 mb-4 sm:mb-6">
          <h1 class="text-2xl sm:text-3xl font-bold text-white mb-4 sm:mb-6">
            {gettext("Edit Topic")}
          </h1>

          <.form for={@form} id="topic-form" phx-change="validate" phx-submit="save">
            <div class="space-y-6">
              <div>
                <.input field={@form[:title]} type="text" label={gettext("Title")} required />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-300 mb-2">
                  {gettext("Content")}
                </label>
                <.quill_editor
                  field={@form[:content]}
                  placeholder={gettext("Write your topic content here...")}
                />
                <p class="mt-2 text-sm text-gray-400">
                  {gettext("Tip: Use the toolbar to format text, add images, and create rich content")}
                </p>
              </div>

              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <.input
                    field={@form[:status]}
                    type="select"
                    label={gettext("Status")}
                    options={Topic.statuses()}
                    required
                  />
                </div>
                <div>
                  <.input
                    field={@form[:language]}
                    type="select"
                    label={gettext("Language")}
                    options={Topic.languages()}
                    required
                  />
                </div>
              </div>

              <div class="flex flex-col sm:flex-row gap-3 sm:gap-4 pt-4">
                <button
                  type="submit"
                  class="w-full sm:w-auto px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-semibold"
                >
                  {gettext("Save Changes")}
                </button>
                <.link
                  navigate={~p"/topics/#{@topic.slug}"}
                  class="w-full sm:w-auto px-6 py-3 bg-gray-700 text-white rounded-lg hover:bg-gray-600 transition-colors font-semibold text-center"
                >
                  {gettext("Cancel")}
                </.link>
              </div>
            </div>
          </.form>
        </div>

        <%!-- References Section --%>
        <div class="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-4 sm:p-6 lg:p-8 border border-gray-700/50">
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-4 sm:mb-6">
            <h2 class="text-xl sm:text-2xl font-bold text-white flex items-center gap-2">
              <.icon name="hero-book-open" class="w-5 h-5 sm:w-6 sm:h-6" />
              {gettext("References")}
            </h2>
            <button
              phx-click="add_reference"
              class="w-full sm:w-auto px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm font-semibold inline-flex items-center justify-center gap-2"
            >
              <.icon name="hero-plus" class="w-4 h-4" />
              {gettext("Add Reference")}
            </button>
          </div>

          <%!-- Reference Form --%>
          <%= if @reference_form do %>
            <div class="mb-6 p-6 bg-gray-700/30 rounded-lg border border-blue-500/30">
              <h3 class="text-lg font-semibold text-white mb-4">
                {if @editing_reference == :new,
                  do: gettext("New Reference"),
                  else: gettext("Edit Reference")}
              </h3>

              <.form
                for={@reference_form}
                id="reference-form"
                phx-change="validate_reference"
                phx-submit="save_reference"
              >
                <div class="space-y-4">
                  <%!-- Quick Add from Resources --%>
                  <%= if @available_resources != [] do %>
                    <div class="p-4 bg-blue-500/10 border border-blue-500/20 rounded-lg">
                      <label class="block text-sm font-medium text-blue-300 mb-2">
                        {gettext("Quick Add from Resources")}
                      </label>
                      <select
                        class="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                        phx-change="select_resource"
                        name="resource_id"
                      >
                        <option value="">{gettext("Select a resource...")}</option>
                        <%= for resource <- @available_resources do %>
                          <option value={resource.id}>
                            [{resource.resource_type}] {resource.title}
                          </option>
                        <% end %>
                      </select>
                      <p class="text-xs text-blue-400 mt-2">
                        {gettext("Select a resource to auto-fill the reference details")}
                      </p>
                    </div>
                  <% end %>

                  <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <.input
                        field={@reference_form[:reference_type]}
                        type="select"
                        label={gettext("Type")}
                        options={TopicReference.reference_types()}
                        required
                      />
                    </div>
                    <div>
                      <.input
                        field={@reference_form[:title]}
                        type="text"
                        label={gettext("Title")}
                        required
                      />
                    </div>
                  </div>

                  <div>
                    <.input field={@reference_form[:url]} type="text" label={gettext("URL")} />
                  </div>

                  <div>
                    <.input
                      field={@reference_form[:description]}
                      type="textarea"
                      label={gettext("Description")}
                      rows="3"
                    />
                  </div>

                  <div class="flex flex-col sm:flex-row gap-2">
                    <button
                      type="submit"
                      class="w-full sm:w-auto px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm font-semibold"
                    >
                      {gettext("Save")}
                    </button>
                    <button
                      type="button"
                      phx-click="cancel_reference"
                      class="w-full sm:w-auto px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-500 transition-colors text-sm font-semibold"
                    >
                      {gettext("Cancel")}
                    </button>
                  </div>
                </div>
              </.form>
            </div>
          <% end %>

          <%!-- References List --%>
          <%= if @references == [] do %>
            <p class="text-gray-500 text-center py-8">
              {gettext("No references yet. Add books, talks, or other resources.")}
            </p>
          <% else %>
            <div class="space-y-3">
              <div
                :for={ref <- @references}
                class="p-4 bg-gray-700/30 rounded-lg border border-gray-700/50 flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4"
              >
                <div class="flex items-start gap-3 flex-1">
                  <div class="p-2 bg-blue-500/10 rounded-lg border border-blue-500/20 shrink-0">
                    <.icon name={reference_icon(ref.reference_type)} class="w-5 h-5 text-blue-400" />
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="flex flex-wrap items-center gap-2 mb-1">
                      <h4 class="font-semibold text-white">{ref.title}</h4>
                      <span class="px-2 py-0.5 bg-gray-700 text-gray-300 rounded text-xs shrink-0">
                        {ref.reference_type}
                      </span>
                    </div>
                    <%= if ref.description do %>
                      <p class="text-sm text-gray-400">{ref.description}</p>
                    <% end %>
                    <%= if ref.url do %>
                      <a
                        href={ref.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        class="text-sm text-blue-400 hover:text-blue-300 mt-1 inline-flex items-center gap-1"
                      >
                        {ref.url}
                        <.icon name="hero-arrow-top-right-on-square" class="w-3 h-3" />
                      </a>
                    <% end %>
                  </div>
                </div>
                <div class="flex flex-col sm:flex-row gap-2 shrink-0">
                  <button
                    phx-click="edit_reference"
                    phx-value-id={ref.id}
                    class="px-3 py-1.5 text-blue-400 hover:text-blue-300 text-sm font-medium whitespace-nowrap"
                  >
                    {gettext("Edit")}
                  </button>
                  <button
                    phx-click="delete_reference"
                    phx-value-id={ref.id}
                    data-confirm={gettext("Are you sure?")}
                    class="px-3 py-1.5 text-red-400 hover:text-red-300 text-sm font-medium whitespace-nowrap"
                  >
                    {gettext("Delete")}
                  </button>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp reference_icon("book"), do: "hero-book-open"
  defp reference_icon("talk"), do: "hero-microphone"
  defp reference_icon("video"), do: "hero-video-camera"
  defp reference_icon("article"), do: "hero-document-text"
  defp reference_icon("website"), do: "hero-globe-alt"
  defp reference_icon(_), do: "hero-link"
end

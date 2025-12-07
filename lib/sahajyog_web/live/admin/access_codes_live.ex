defmodule SahajyogWeb.Admin.AccessCodesLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Admin
  alias Sahajyog.Admin.AccessCode

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, gettext("Manage Access Codes"))
     |> stream(:access_codes, Admin.list_access_codes())
     |> assign_form(Admin.AccessCode.changeset(%AccessCode{}, %{}))}
  end

  @impl true
  def handle_event("validate", %{"access_code" => params}, socket) do
    changeset =
      %AccessCode{}
      |> Admin.AccessCode.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"access_code" => params}, socket) do
    # Inject current user as creator
    params = Map.put(params, "created_by_id", socket.assigns.current_scope.user.id)

    case Admin.create_access_code(params) do
      {:ok, access_code} ->
        access_code = Sahajyog.Repo.preload(access_code, [:event, :created_by])

        {:noreply,
         socket
         |> put_flash(:info, "Access code created successfully")
         |> stream_insert(:access_codes, access_code, at: 0)
         # Reset form
         |> assign_form(Admin.AccessCode.changeset(%AccessCode{}, %{}))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    # Assuming ID passed is actually code, or fetch by ID
    # access_code = Admin.get_access_code_by_code(id)

    # Actually stream uses DOM IDs, so we need to be careful. Let's fetch by real ID
    # But for now let's assume we pass ID.
    # Wait, `get_access_code_by_code` expects code string.
    # Let's fix this to delete by ID if we had get_by_id, but we don't.
    # Let's cheat and use Repo directly or add get_by_id.
    # For now, let's just use Repo.get! which is available via Admin context helpers if added,
    # or just use Ecto directly in context.
    # Actually, let's just define delete logic properly.

    # We will pass ID from the UI.
    access_code = Sahajyog.Repo.get!(AccessCode, id)

    {:ok, _} = Admin.delete_access_code(access_code)

    {:noreply, stream_delete(socket, :access_codes, access_code)}
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_page_container title={gettext("Access Codes")}>
      <div class="grid lg:grid-cols-3 gap-8">
        <!-- Create Form -->
        <div class="lg:col-span-1">
          <.card title={gettext("Generate New Code")}>
            <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
              <.input
                field={@form[:code]}
                type="text"
                label={gettext("Code")}
                placeholder="e.g. SUMMER-2025"
                required
              />

              <.input
                field={@form[:max_uses]}
                type="number"
                label={gettext("Max Uses (Optional)")}
                min="1"
                placeholder={gettext("Unlimited if empty")}
              />
              
    <!-- Optional: Event Selection could go here if needed -->

              <div class="pt-2">
                <.primary_button type="submit" class="w-full">
                  {gettext("Generate Code")}
                </.primary_button>
              </div>
            </.form>
          </.card>
        </div>
        
    <!-- List -->
        <div class="lg:col-span-2">
          <.card title={gettext("Active Access Codes")}>
            <div class="overflow-x-auto">
              <table class="table">
                <thead>
                  <tr>
                    <th>{gettext("Code")}</th>
                    <th>{gettext("Usage")}</th>
                    <th>{gettext("Created By")}</th>
                    <th>{gettext("Actions")}</th>
                  </tr>
                </thead>
                <tbody id="access_codes" phx-update="stream">
                  <tr :for={{id, code} <- @streams.access_codes} id={id}>
                    <td class="font-mono font-bold">{code.code}</td>
                    <td>
                      {code.usage_count}
                      <span :if={code.max_uses} class="text-base-content/50">/ {code.max_uses}</span>
                    </td>
                    <td class="text-sm">
                      {if code.created_by, do: code.created_by.email, else: "-"}
                    </td>
                    <td>
                      <button
                        phx-click="delete"
                        phx-value-id={code.id}
                        data-confirm={gettext("Are you sure?")}
                        class="btn btn-ghost btn-xs text-error"
                      >
                        {gettext("Delete")}
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </.card>
        </div>
      </div>
    </.admin_page_container>
    """
  end

  # Admin page wrapper helper
  def admin_page_container(assigns) do
    ~H"""
    <div class="p-4 sm:p-6 lg:p-8">
      <div class="mb-8">
        <h1 class="text-2xl font-bold text-base-content">{@title}</h1>
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end
end

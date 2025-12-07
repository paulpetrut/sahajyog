defmodule SahajyogWeb.LevelUpgradeLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Events

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Upgrade Access Level")
     |> assign(:code, "")
     |> assign(:error_message, nil)}
  end

  @impl true
  def handle_event("validate", %{"code" => code}, socket) do
    {:noreply, assign(socket, :code, code)}
  end

  @impl true
  def handle_event("upgrade", %{"code" => code}, socket) do
    code = String.trim(code)
    user = socket.assigns.current_scope.user

    case Events.upgrade_user_via_code(user, code) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           gettext("Congratulations! You have been upgraded to Level 2 access.")
         )
         # Update current scope's user to reflect changes immediately in UI if navigating away
         |> assign(:current_scope, %{socket.assigns.current_scope | user: updated_user})
         |> push_navigate(to: ~p"/events")}

      {:error, :invalid_code} ->
        {:noreply,
         assign(
           socket,
           :error_message,
           gettext("Invalid upgrade code. Please check and try again.")
         )}

      {:error, :already_upgraded} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("You are already at Level 2 or higher."))
         |> push_navigate(to: ~p"/events")}

      {:error, _} ->
        {:noreply,
         assign(socket, :error_message, gettext("Something went wrong. Please try again."))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_container>
      <div class="max-w-md mx-auto px-4 py-16">
        <.card>
          <div class="text-center mb-8">
            <h1 class="text-2xl font-bold text-base-content mb-2">
              {gettext("Upgrade Access Level")}
            </h1>
            <p class="text-base-content/60">
              {gettext("Enter an event upgrade code to unlock Level 2 access.")}
            </p>
          </div>

          <form phx-submit="upgrade" phx-change="validate">
            <div class="space-y-4">
              <div>
                <.input
                  type="text"
                  name="code"
                  value={@code}
                  label={gettext("Upgrade Code")}
                  placeholder="e.g. London-20241225-Retreat"
                  required
                />
                <%= if @error_message do %>
                  <p class="text-error text-sm mt-1">{@error_message}</p>
                <% end %>
              </div>

              <div class="pt-2">
                <.primary_button type="submit" class="w-full">
                  {gettext("Unlock Level 2 Access")}
                </.primary_button>
              </div>
            </div>
          </form>

          <div class="mt-8 text-center bg-base-200/50 rounded-lg p-4">
            <p class="text-base font-medium text-base-content">
              {gettext("To obtain an upgrade code, please get in touch with the admin using the")}
              <.link navigate={~p"/contact"} class="link link-primary font-bold">
                {gettext("Contact Form")}
              </.link>.
            </p>
          </div>

          <div class="mt-6 text-center">
            <.link navigate={~p"/events"} class="text-sm text-base-content/50 hover:text-base-content">
              {gettext("Back to Events")}
            </.link>
          </div>
        </.card>
      </div>
    </.page_container>
    """
  end
end

defmodule SahajyogWeb.UserLive.ResetPassword do
  @moduledoc """
  LiveView for resetting user password using a token.
  """
  use SahajyogWeb, :live_view

  alias Sahajyog.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen flex items-center justify-center bg-base-200 px-4 py-12">
        <div class="w-full max-w-md">
          <%!-- Header --%>
          <div class="text-center mb-8">
            <h1 class="text-4xl font-bold mb-3">{gettext("Reset Password")}</h1>
            <p class="text-base-content/70">
              {gettext("Enter your new password below.")}
            </p>
          </div>

          <%!-- Main card --%>
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <.form
                for={@form}
                id="reset_password_form"
                phx-change="validate"
                phx-submit="reset"
              >
                <.input
                  field={@form[:password]}
                  type="password"
                  label={gettext("New password")}
                  placeholder={gettext("At least 12 characters")}
                  autocomplete="new-password"
                  required
                  phx-mounted={JS.focus()}
                />

                <.input
                  field={@form[:password_confirmation]}
                  type="password"
                  label={gettext("Confirm new password")}
                  placeholder={gettext("Re-enter your password")}
                  autocomplete="new-password"
                  required
                />

                <.button class="btn btn-primary w-full text-lg h-12 rounded-full shadow-lg hover:shadow-xl transition-all mt-4">
                  <span class="flex items-center justify-center gap-2 font-semibold">
                    <.icon name="hero-key" class="w-5 h-5" />
                    {gettext("Reset password")}
                  </span>
                </.button>
              </.form>
            </div>
          </div>

          <%!-- Back to login link --%>
          <p class="mt-6 text-center text-sm">
            <.link navigate={~p"/users/log-in"} class="link link-primary font-semibold">
              <.icon name="hero-arrow-left" class="w-4 h-4 inline" />
              {gettext("Back to login")}
            </.link>
          </p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket = assign(socket, page_title: gettext("Reset Password"), token: token)

    case Accounts.get_user_by_reset_password_token(token) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, gettext("Reset password link is invalid or has expired."))
         |> push_navigate(to: ~p"/users/forgot-password")}

      user ->
        form = Accounts.change_user_password(user) |> to_form(as: "user")
        {:ok, assign(socket, user: user, form: form)}
    end
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: "user"))}
  end

  def handle_event("reset", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           gettext("Password reset successfully. Please log in with your new password.")
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "user"))}
    end
  end
end

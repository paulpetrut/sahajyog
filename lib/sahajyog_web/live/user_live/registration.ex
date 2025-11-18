defmodule SahajyogWeb.UserLive.Registration do
  use SahajyogWeb, :live_view

  alias Sahajyog.Accounts
  alias Sahajyog.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <div class="text-center">
          <.header>
            {gettext("Register for an account")}
            <:subtitle>
              {gettext("Already registered?")}
              <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
                {gettext("Log in")}
              </.link>
              {gettext("to your account now.")}
            </:subtitle>
          </.header>
        </div>

        <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
          <.input
            field={@form[:email]}
            type="email"
            label={gettext("Email")}
            autocomplete="username"
            required
            phx-mounted={JS.focus()}
          />

          <.input
            field={@form[:password]}
            type="password"
            label={gettext("Password (optional)")}
            placeholder={gettext("Leave blank to use magic link login")}
            autocomplete="new-password"
          />

          <.input
            field={@form[:password_confirmation]}
            type="password"
            label={gettext("Confirm password (optional)")}
            placeholder={gettext("Only if you set a password above")}
            autocomplete="new-password"
          />

          <.button phx-disable-with={gettext("Creating account...")} class="btn btn-primary w-full">
            {gettext("Create an account")}
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: SahajyogWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_email(%User{}, %{})

    socket = assign(socket, :page_title, gettext("Register"))

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        locale = Gettext.get_locale(SahajyogWeb.Gettext)

        case Accounts.deliver_login_instructions(
               user,
               &url(~p"/users/log-in/#{&1}"),
               locale
             ) do
          {:ok, _} ->
            {:noreply,
             socket
             |> put_flash(
               :info,
               gettext("An email was sent to %{email}, please access it to confirm your account.",
                 email: user.email
               )
             )
             |> push_navigate(to: ~p"/users/log-in")}

          {:error, _reason} ->
            require Logger
            Logger.error("Failed to send confirmation email to #{user.email}")

            {:noreply,
             socket
             |> put_flash(
               :error,
               gettext(
                 "Account created but we couldn't send the confirmation email. Please contact support."
               )
             )
             |> push_navigate(to: ~p"/users/log-in")}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    # If password is empty, remove it from params to allow passwordless registration
    user_params =
      if user_params["password"] == "" or user_params["password"] == nil do
        Map.drop(user_params, ["password", "password_confirmation"])
      else
        user_params
      end

    changeset = Accounts.change_user_email(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end

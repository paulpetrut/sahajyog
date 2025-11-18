defmodule SahajyogWeb.UserLive.Login do
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
            <h1 class="text-4xl font-bold mb-3">{gettext("Welcome back")}</h1>
            <p class="text-base-content/70">
              <%= if @current_scope do %>
                {gettext("Please reauthenticate to continue")}
              <% else %>
                {gettext("Sign in to your account to continue")}
              <% end %>
            </p>
          </div>

          <%!-- Dev mode notice --%>
          <div :if={local_mail_adapter?()} class="alert alert-warning mb-6">
            <.icon name="hero-exclamation-triangle" class="size-5 shrink-0" />
            <div class="text-sm">
              <span class="font-medium">{gettext("Dev mode:")}</span>
              <.link href="/dev/mailbox" class="underline ml-1">{gettext("View mailbox")}</.link>
            </div>
          </div>

          <%!-- Main card --%>
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <%!-- Password Form --%>
              <.form
                for={@form}
                id="login_form_password"
                action={~p"/users/log-in"}
                phx-submit="submit_password"
                phx-trigger-action={@trigger_submit}
              >
                <.input
                  readonly={!!@current_scope}
                  field={@form[:email]}
                  type="email"
                  label={gettext("Email")}
                  placeholder={gettext("you@example.com")}
                  autocomplete="username"
                  required
                  phx-mounted={JS.focus()}
                />

                <.input
                  field={@form[:password]}
                  type="password"
                  label={gettext("Password")}
                  placeholder={gettext("Enter your password")}
                  autocomplete="current-password"
                  required
                />

                <div class="form-control">
                  <label class="label cursor-pointer justify-start gap-3">
                    <input
                      type="checkbox"
                      name="remember_me_checkbox"
                      checked={@remember_me}
                      phx-click="toggle_remember"
                      class="checkbox checkbox-primary"
                    />
                    <span class="label-text">{gettext("Keep me signed in")}</span>
                  </label>
                </div>

                <.button
                  class="btn btn-primary w-full text-lg h-12 rounded-full shadow-lg hover:shadow-xl transition-all"
                  name={@form[:remember_me].name}
                  value={if @remember_me, do: "true", else: "false"}
                >
                  <span class="flex items-center justify-center gap-2 font-semibold">
                    <.icon name="hero-arrow-right-on-rectangle" class="w-5 h-5" /> {gettext("Sign in")}
                  </span>
                </.button>
              </.form>

              <%!-- Divider --%>
              <div class="divider">{gettext("OR")}</div>

              <%!-- Magic Link Form --%>
              <.form
                for={@form}
                id="login_form_magic"
                action={~p"/users/log-in"}
                phx-submit="submit_magic"
              >
                <button
                  type="button"
                  phx-click="toggle_magic_form"
                  class={[
                    "btn w-full h-12 text-base font-semibold rounded-full",
                    @show_magic_form && "btn-primary",
                    !@show_magic_form && "btn-outline btn-primary"
                  ]}
                >
                  <span class="flex items-center justify-center gap-2">
                    <.icon name="hero-envelope" class="w-5 h-5" /> {gettext(
                      "Magic link (passwordless)"
                    )}
                  </span>
                </button>

                <div :if={@show_magic_form} class="mt-4 p-4 bg-base-200 rounded-lg space-y-4">
                  <p class="text-sm text-base-content/70">
                    {gettext("We'll email you a secure link to sign in without a password.")}
                  </p>

                  <.input
                    readonly={!!@current_scope}
                    field={@form[:email]}
                    type="email"
                    label={gettext("Email")}
                    placeholder={gettext("you@example.com")}
                    autocomplete="username"
                    required
                  />

                  <.button class="btn btn-primary w-full text-lg h-12 rounded-full shadow-lg hover:shadow-xl transition-all">
                    <span class="flex items-center justify-center gap-2 font-semibold">
                      <.icon name="hero-paper-airplane" class="w-5 h-5" /> {gettext("Send magic link")}
                    </span>
                  </.button>
                </div>
              </.form>
            </div>
          </div>

          <%!-- Sign up link --%>
          <p :if={!@current_scope} class="mt-6 text-center text-sm">
            {gettext("Don't have an account?")}
            <.link navigate={~p"/users/register"} class="link link-primary font-semibold">
              {gettext("Sign up")}
            </.link>
          </p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok,
     assign(socket,
       page_title: "Log in",
       form: form,
       trigger_submit: false,
       remember_me: true,
       show_magic_form: false
     )}
  end

  @impl true
  def handle_event("toggle_remember", _params, socket) do
    {:noreply, assign(socket, :remember_me, !socket.assigns.remember_me)}
  end

  def handle_event("toggle_magic_form", _params, socket) do
    {:noreply, assign(socket, :show_magic_form, !socket.assigns.show_magic_form)}
  end

  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      locale = Gettext.get_locale(SahajyogWeb.Gettext)

      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}"),
        locale
      )
    end

    info =
      "Check your email! If your address is in our system, you'll receive a sign-in link shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> assign(:show_magic_form, true)}
  end

  defp local_mail_adapter? do
    Application.get_env(:sahajyog, Sahajyog.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end

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
              <%!-- Tab Buttons --%>
              <div class="grid grid-cols-2 gap-3 mb-6">
                <button
                  type="button"
                  phx-click="show_password_form"
                  class={[
                    "btn btn-lg h-16 flex-col gap-1 transition-all",
                    !@show_magic_form && "btn-primary shadow-lg",
                    @show_magic_form && "btn-outline btn-ghost"
                  ]}
                >
                  <.icon name="hero-lock-closed" class="w-6 h-6" />
                  <span class="text-sm font-semibold">{gettext("Password")}</span>
                </button>
                <button
                  type="button"
                  phx-click="show_magic_form"
                  class={[
                    "btn btn-lg h-16 flex-col gap-1 transition-all",
                    @show_magic_form && "btn-primary shadow-lg",
                    !@show_magic_form && "btn-outline btn-ghost"
                  ]}
                >
                  <.icon name="hero-envelope" class="w-6 h-6" />
                  <span class="text-sm font-semibold">{gettext("Magic Link")}</span>
                </button>
              </div>

              <%!-- Password Form --%>
              <div :if={!@show_magic_form}>
                <.form
                  for={@form}
                  id="login_form_password"
                  action={~p"/users/log-in"}
                  phx-submit="submit_password"
                  phx-trigger-action={@trigger_submit}
                >
                  <input :if={@return_to} type="hidden" name="return_to" value={@return_to} />
                  <.input
                    readonly={!!@current_scope}
                    field={@form[:email]}
                    type="email"
                    label={gettext("Email")}
                    placeholder={gettext("you@example.com")}
                    autocomplete="username"
                    required
                    phx-mounted={JS.focus()}
                    id="user_email"
                  />

                  <.input
                    field={@form[:password]}
                    type="password"
                    label={gettext("Password")}
                    placeholder={gettext("Enter your password")}
                    autocomplete="current-password"
                    required
                  />

                  <div class="flex items-center justify-between">
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
                    <.link
                      navigate={~p"/users/forgot-password"}
                      class="text-sm link link-primary"
                    >
                      {gettext("Forgot password?")}
                    </.link>
                  </div>

                  <.button
                    class="btn btn-primary w-full text-lg h-12 rounded-full shadow-lg hover:shadow-xl transition-all"
                    name={@form[:remember_me].name}
                    value={if @remember_me, do: "true", else: "false"}
                  >
                    <span class="flex items-center justify-center gap-2 font-semibold">
                      <.icon name="hero-arrow-right-on-rectangle" class="w-5 h-5" /> {gettext(
                        "Sign in"
                      )}
                    </span>
                  </.button>
                </.form>
              </div>

              <%!-- Magic Link Form --%>
              <div :if={@show_magic_form}>
                <.form
                  for={@form}
                  id="login_form_magic"
                  action={~p"/users/log-in"}
                  phx-submit="submit_magic"
                >
                  <p class="text-sm text-base-content/70 mb-4">
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
                    id="user_email_magic"
                  />

                  <.button class="btn btn-primary w-full text-lg h-12 rounded-full shadow-lg hover:shadow-xl transition-all">
                    <span class="flex items-center justify-center gap-2 font-semibold">
                      <.icon name="hero-paper-airplane" class="w-5 h-5" /> {gettext("Send magic link")}
                    </span>
                  </.button>
                </.form>
              </div>
            </div>
          </div>

          <%!-- Sign up link --%>
          <p :if={!@current_scope} class="mt-6 text-center text-sm">
            {gettext("Don't have an account?")}
            <.link
              navigate={
                if @return_to,
                  do: ~p"/users/register?return_to=#{@return_to}",
                  else: ~p"/users/register"
              }
              class="link link-primary font-semibold"
            >
              {gettext("Sign up")}
            </.link>
          </p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    # Get return_to from params or session
    return_to = params["return_to"] || session["user_return_to"]

    {:ok,
     assign(socket,
       page_title: "Log in",
       form: form,
       trigger_submit: false,
       remember_me: true,
       show_magic_form: false,
       return_to: return_to
     )}
  end

  @impl true
  def handle_event("toggle_remember", _params, socket) do
    {:noreply, assign(socket, :remember_me, !socket.assigns.remember_me)}
  end

  def handle_event("show_password_form", _params, socket) do
    {:noreply, assign(socket, :show_magic_form, false)}
  end

  def handle_event("show_magic_form", _params, socket) do
    {:noreply, assign(socket, :show_magic_form, true)}
  end

  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      locale = Gettext.get_locale(SahajyogWeb.Gettext)

      case Accounts.deliver_login_instructions(
             user,
             &url(~p"/users/log-in/#{&1}"),
             locale
           ) do
        {:ok, _} ->
          info =
            gettext(
              "Check your email! If your address is in our system, you'll receive a sign-in link shortly."
            )

          {:noreply,
           socket
           |> put_flash(:info, info)
           |> assign(:show_magic_form, true)}

        {:error, reason} ->
          require Logger
          Logger.error("Failed to send magic link email: #{inspect(reason)}")

          {:noreply,
           socket
           |> put_flash(
             :error,
             gettext(
               "Failed to send email. Please try again or contact support if the problem persists."
             )
           )
           |> assign(:show_magic_form, true)}
      end
    else
      # User not found - still show success message to prevent email enumeration
      info =
        gettext(
          "Check your email! If your address is in our system, you'll receive a sign-in link shortly."
        )

      {:noreply,
       socket
       |> put_flash(:info, info)
       |> assign(:show_magic_form, true)}
    end
  end

  defp local_mail_adapter? do
    Application.get_env(:sahajyog, Sahajyog.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end

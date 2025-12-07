defmodule SahajyogWeb.UserLive.ForgotPassword do
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
            <h1 class="text-4xl font-bold mb-3">{gettext("Forgot your password?")}</h1>
            <p class="text-base-content/70">
              {gettext("Enter your email and we'll send you a link to reset your password.")}
            </p>
          </div>

          <%!-- Main card --%>
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <.form for={@form} id="forgot_password_form" phx-submit="send_instructions">
                <.input
                  field={@form[:email]}
                  type="email"
                  label={gettext("Email")}
                  placeholder={gettext("you@example.com")}
                  autocomplete="email"
                  required
                  phx-mounted={JS.focus()}
                />

                <.button class="btn btn-primary w-full text-lg h-12 rounded-full shadow-lg hover:shadow-xl transition-all mt-4">
                  <span class="flex items-center justify-center gap-2 font-semibold">
                    <.icon name="hero-envelope" class="w-5 h-5" />
                    {gettext("Send reset instructions")}
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
  def mount(_params, _session, socket) do
    form = to_form(%{"email" => ""}, as: "user")

    {:ok,
     assign(socket,
       page_title: gettext("Forgot Password"),
       form: form
     )}
  end

  @impl true
  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    email = String.trim(email)

    if valid_email_format?(email) do
      locale = Gettext.get_locale(SahajyogWeb.Gettext)

      # Always show success message regardless of whether user exists
      # This prevents email enumeration attacks
      Accounts.deliver_password_reset_instructions(
        email,
        &url(~p"/users/reset-password/#{&1}"),
        locale
      )

      info =
        gettext(
          "If your email is in our system and has a password, you will receive reset instructions shortly."
        )

      {:noreply,
       socket
       |> put_flash(:info, info)
       |> push_navigate(to: ~p"/users/log-in")}
    else
      form =
        %{"email" => email}
        |> to_form(as: "user")
        |> Map.put(:errors, email: {gettext("must be a valid email address"), []})
        |> Map.put(:action, :validate)

      {:noreply, assign(socket, form: form)}
    end
  end

  defp valid_email_format?(email) when is_binary(email) do
    # Basic email validation:
    # - Must not be empty/whitespace
    # - Must have @ with content on both sides
    # - Must not contain spaces
    email = String.trim(email)

    case String.split(email, "@") do
      [local, domain] when local != "" and domain != "" ->
        not String.contains?(email, " ")

      _ ->
        false
    end
  end
end

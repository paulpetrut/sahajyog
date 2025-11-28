defmodule SahajyogWeb.ContactLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.ContactNotifier

  @impl true
  def mount(_params, _session, socket) do
    form =
      %{
        "name" => "",
        "email" => get_user_email(socket),
        "subject" => "",
        "message" => ""
      }
      |> to_form()

    {:ok,
     socket
     |> assign(:page_title, gettext("Contact Us"))
     |> assign(:form, form)
     |> assign(:submitted, false)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    form = params |> to_form()
    {:noreply, assign(socket, form: form)}
  end

  @impl true
  def handle_event("submit", params, socket) do
    %{"name" => name, "email" => email, "subject" => subject, "message" => message} = params

    errors = validate_contact_form(params)

    if errors == [] do
      case ContactNotifier.deliver_contact_message(name, email, subject, message) do
        {:ok, _} ->
          {:noreply,
           socket
           |> assign(:submitted, true)
           |> put_flash(:info, gettext("Message sent successfully! We'll get back to you soon."))}

        {:error, _reason} ->
          {:noreply,
           socket
           |> put_flash(
             :error,
             gettext("Failed to send message. Please try again or email us directly.")
           )}
      end
    else
      form =
        params
        |> to_form()
        |> Map.put(:errors, errors)

      {:noreply, assign(socket, form: form)}
    end
  end

  defp validate_contact_form(params) do
    errors = []

    errors =
      if blank?(params["name"]) do
        [{:name, {gettext("Name is required"), []}} | errors]
      else
        errors
      end

    errors =
      if blank?(params["email"]) do
        [{:email, {gettext("Email is required"), []}} | errors]
      else
        if valid_email?(params["email"]) do
          errors
        else
          [{:email, {gettext("Email is invalid"), []}} | errors]
        end
      end

    errors =
      if blank?(params["subject"]) do
        [{:subject, {gettext("Subject is required"), []}} | errors]
      else
        errors
      end

    errors =
      if blank?(params["message"]) do
        [{:message, {gettext("Message is required"), []}} | errors]
      else
        errors
      end

    Enum.reverse(errors)
  end

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(str) when is_binary(str), do: String.trim(str) == ""
  defp blank?(_), do: false

  defp valid_email?(email) do
    String.match?(email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)
  end

  defp get_user_email(socket) do
    case socket.assigns[:current_scope] do
      %{user: %{email: email}} -> email
      _ -> ""
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen bg-base-100 py-12 px-4 sm:px-6 lg:px-8">
        <div class="max-w-2xl mx-auto">
          <%!-- Header --%>
          <div class="text-center mb-8">
            <h1 class="text-4xl font-bold text-base-content mb-3">
              {gettext("Contact Us")}
            </h1>
            <p class="text-lg text-base-content/70">
              {gettext("Have a question or feedback? We'd love to hear from you.")}
            </p>
          </div>

          <%= if @submitted do %>
            <%!-- Success Message --%>
            <div class="bg-success/10 border border-success/20 rounded-lg p-6 text-center">
              <div class="flex justify-center mb-4">
                <.icon name="hero-check-circle" class="w-16 h-16 text-success" />
              </div>
              <h2 class="text-2xl font-semibold text-base-content mb-2">
                {gettext("Thank you for reaching out!")}
              </h2>
              <p class="text-base-content/70 mb-6">
                {gettext("We've received your message and will respond as soon as possible.")}
              </p>
              <.link
                navigate={~p"/"}
                class="inline-flex items-center gap-2 px-6 py-3 bg-primary text-primary-content rounded-lg hover:bg-primary/90 transition-colors"
              >
                {gettext("Back to Home")}
              </.link>
            </div>
          <% else %>
            <%!-- Contact Form --%>
            <div class="bg-base-200 rounded-lg shadow-lg p-8">
              <.form
                for={@form}
                id="contact-form"
                phx-change="validate"
                phx-submit="submit"
                class="space-y-6"
              >
                <.input
                  field={@form[:name]}
                  type="text"
                  label={gettext("Name")}
                  placeholder={gettext("Your name")}
                  required
                />

                <.input
                  field={@form[:email]}
                  type="email"
                  label={gettext("Email")}
                  placeholder={gettext("your.email@example.com")}
                  required
                />

                <.input
                  field={@form[:subject]}
                  type="text"
                  label={gettext("Subject")}
                  placeholder={gettext("What is this about?")}
                  required
                />

                <.input
                  field={@form[:message]}
                  type="textarea"
                  label={gettext("Message")}
                  placeholder={gettext("Tell us more...")}
                  rows="6"
                  required
                />

                <div class="flex gap-4">
                  <button
                    type="submit"
                    class="flex-1 px-6 py-3 bg-primary text-primary-content rounded-lg hover:bg-primary/90 transition-colors font-medium"
                  >
                    {gettext("Send Message")}
                  </button>
                  <.link
                    navigate={~p"/"}
                    class="px-6 py-3 bg-base-300 text-base-content rounded-lg hover:bg-base-300/80 transition-colors font-medium"
                  >
                    {gettext("Cancel")}
                  </.link>
                </div>
              </.form>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end
end

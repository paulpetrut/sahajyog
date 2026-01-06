defmodule SahajyogWeb.UserLive.Settings do
  use SahajyogWeb, :live_view

  alias Sahajyog.Accounts
  alias Sahajyog.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 py-8 noise-overlay">
        <div class="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8">
          <%= if @return_to do %>
            <div class="mb-6">
              <.link
                navigate={@return_to}
                class="text-info hover:text-info/80 inline-flex items-center gap-2 focus:outline-none focus:ring-2 focus:ring-info focus:ring-offset-2 focus:ring-offset-base-300 rounded"
              >
                <.icon name="hero-arrow-left" class="w-4 h-4" />
                {gettext("Back to Event")}
              </.link>
            </div>
          <% end %>

          <div class="text-center mb-8">
            <h1 class="text-3xl font-bold text-white mb-2">{gettext("Account Settings")}</h1>
            <p class="text-gray-400">
              {gettext("Manage your account email address and password settings")}
            </p>
          </div>
          <div class="bg-gray-800 rounded-lg border border-gray-700 shadow-xl p-6 mb-6">
            <div class="mb-4">
              <h2 class="text-xl font-semibold text-white">{gettext("Profile Information")}</h2>
              <p class="text-sm text-gray-400 mt-1">{gettext("These details are optional.")}</p>
            </div>
            <.form
              for={@profile_form}
              id="profile_form"
              phx-submit="update_profile"
              phx-change="validate_profile"
            >
              <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <.input field={@profile_form[:first_name]} type="text" label={gettext("First Name")} />
                <.input field={@profile_form[:last_name]} type="text" label={gettext("Last Name")} />
              </div>
              <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 mt-4">
                <.input field={@profile_form[:city]} type="text" label={gettext("City")} />
                <.input
                  field={@profile_form[:country]}
                  type="select"
                  label={gettext("Country")}
                  options={@country_options}
                  prompt={gettext("Select a country")}
                />
              </div>
              <div class="mt-4">
                <label class="form-control">
                  <span class="label">
                    <span class="label-text">{gettext("Phone Number")}</span>
                  </span>
                  <div class="join w-full">
                    <div class="join-item flex items-center px-3 bg-base-200 border border-base-300 text-base-content/70 select-none rounded-l-lg">
                      {@phone_prefix}
                    </div>
                    <input
                      type="tel"
                      name={@profile_form[:phone_number].name}
                      id={@profile_form[:phone_number].id}
                      value={@profile_form[:phone_number].value}
                      class="join-item input input-bordered w-full rounded-r-lg"
                      placeholder="123456789"
                    />
                  </div>
                </label>
              </div>
              <div class="mt-4">
                <.button variant="primary" phx-disable-with={gettext("Saving...")}>
                  {gettext("Save Profile")}
                </.button>
              </div>
            </.form>
          </div>

          <div class="bg-gray-800 rounded-lg border border-gray-700 shadow-xl p-6 mb-6">
            <h2 class="text-xl font-semibold text-white mb-4">{gettext("Email Address")}</h2>
            <.form
              for={@email_form}
              id="email_form"
              phx-submit="update_email"
              phx-change="validate_email"
            >
              <.input
                field={@email_form[:email]}
                type="email"
                label={gettext("Email")}
                autocomplete="username"
                required
              />
              <div class="mt-4">
                <.button variant="primary" phx-disable-with={gettext("Changing...")}>
                  {gettext("Change Email")}
                </.button>
              </div>
            </.form>
          </div>

          <div class="bg-gray-800 rounded-lg border border-gray-700 shadow-xl p-6">
            <h2 class="text-xl font-semibold text-white mb-4">{gettext("Change Password")}</h2>
            <.form
              for={@password_form}
              id="password_form"
              action={~p"/users/update-password"}
              method="post"
              phx-change="validate_password"
              phx-submit="update_password"
              phx-trigger-action={@trigger_submit}
            >
              <input
                name={@password_form[:email].name}
                type="hidden"
                id="hidden_user_email"
                autocomplete="username"
                value={@current_email}
              />
              <.input
                field={@password_form[:password]}
                type="password"
                label={gettext("New password")}
                autocomplete="new-password"
                required
              />
              <.input
                field={@password_form[:password_confirmation]}
                type="password"
                label={gettext("Confirm new password")}
                autocomplete="new-password"
              />
              <div class="mt-4">
                <.button variant="primary" phx-disable-with={gettext("Saving...")}>
                  {gettext("Save Password")}
                </.button>
              </div>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, gettext("Email changed successfully."))

        {:error, _} ->
          put_flash(socket, :error, gettext("Email change link is invalid or it has expired."))
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)

    country_codes = User.country_codes()
    country_options = Enum.map(country_codes, fn {name, _code} -> name end) |> Enum.sort()

    # Determine initial prefix based on user's country or default to +1
    initial_prefix = get_prefix_for_country(user.country, country_codes)

    socket =
      socket
      |> assign(:page_title, "Settings")
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:profile_form, to_form(Accounts.change_user_profile(user)))
      |> assign(:country_options, country_options)
      |> assign(:country_codes, country_codes)
      |> assign(:phone_prefix, initial_prefix)
      |> assign(:trigger_submit, false)
      |> assign(:return_to, params["return_to"])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    # Ensure param is decoded if double-encoded, though Phoenix usually handles one layer.
    return_to =
      case params["return_to"] do
        nil -> nil
        val -> URI.decode(val)
      end

    {:noreply, assign(socket, :return_to, return_to)}
  end

  defp get_prefix_for_country(country, country_codes) do
    case List.keyfind(country_codes, country, 0) do
      {_, code} -> code
      # Default fallback
      nil -> "+1"
    end
  end

  @impl true
  def handle_event("validate_profile", params, socket) do
    %{"user" => user_params} = params

    # Update prefix if country changed
    country = user_params["country"]
    phone_prefix = get_prefix_for_country(country, socket.assigns.country_codes)

    profile_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_profile(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply,
     socket
     |> assign(profile_form: profile_form)
     |> assign(phone_prefix: phone_prefix)}
  end

  def handle_event("update_profile", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user

    case Accounts.update_user_profile(user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Profile updated successfully."))
         |> push_navigate(to: socket.assigns.return_to || ~p"/users/settings")}

      {:error, changeset} ->
        {:noreply, assign(socket, profile_form: to_form(changeset))}
    end
  end

  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user

    if Accounts.sudo_mode?(user) do
      case Accounts.change_user_email(user, user_params) do
        %{valid?: true} = changeset ->
          Accounts.deliver_user_update_email_instructions(
            Ecto.Changeset.apply_action!(changeset, :insert),
            user.email,
            &url(~p"/users/settings/confirm-email/#{&1}")
          )

          info = gettext("A link to confirm your email change has been sent to the new address.")
          {:noreply, socket |> put_flash(:info, info)}

        changeset ->
          {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
      end
    else
      {:noreply,
       socket
       |> put_flash(
         :error,
         gettext("Your session has expired. Please log in again to make changes.")
       )
       |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user

    if Accounts.sudo_mode?(user) do
      case Accounts.change_user_password(user, user_params) do
        %{valid?: true} = changeset ->
          {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

        changeset ->
          {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
      end
    else
      {:noreply,
       socket
       |> put_flash(
         :error,
         gettext("Your session has expired. Please log in again to make changes.")
       )
       |> push_navigate(to: ~p"/users/log-in")}
    end
  end
end

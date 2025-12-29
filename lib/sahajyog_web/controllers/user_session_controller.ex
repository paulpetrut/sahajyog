defmodule SahajyogWeb.UserSessionController do
  use SahajyogWeb, :controller

  alias Sahajyog.Accounts
  alias SahajyogWeb.UserAuth

  def create(conn, %{"_action" => "confirmed"} = params) do
    create(conn, params, gettext("User confirmed successfully."))
  end

  def create(conn, params) do
    create(conn, params, nil)
  end

  # magic link login
  defp create(conn, %{"user" => %{"token" => token} = user_params}, info) do
    case Accounts.login_user_by_magic_link(token) do
      {:ok, {user, tokens_to_disconnect}} ->
        UserAuth.disconnect_sessions(tokens_to_disconnect)

        # Check if first login BEFORE creating the new session
        flash_message = info || welcome_message(user)

        conn
        |> put_flash(:info, flash_message)
        |> UserAuth.log_in_user(user, user_params)

      {:error, :password_required} ->
        conn
        |> put_flash(
          :info,
          gettext("Your account has been confirmed! Please log in with your password.")
        )
        |> redirect(to: ~p"/users/log-in")

      _ ->
        conn
        |> put_flash(:error, gettext("The link is invalid or it has expired."))
        |> redirect(to: ~p"/users/log-in")
    end
  end

  # email + password login
  defp create(conn, %{"user" => user_params} = params, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      # Check if first login BEFORE creating the new session
      flash_message = info || welcome_message(user)

      # Store return_to in session if provided
      conn =
        case params["return_to"] do
          nil -> conn
          "" -> conn
          return_to -> put_session(conn, :user_return_to, return_to)
        end

      conn
      |> put_flash(:info, flash_message)
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, gettext("Invalid email or password"))
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log-in")
    end
  end

  def update_password(conn, %{"user" => user_params} = params) do
    user = conn.assigns.current_scope.user

    if Accounts.sudo_mode?(user) do
      {:ok, {_user, expired_tokens}} = Accounts.update_user_password(user, user_params)

      # disconnect all existing LiveViews with old sessions
      UserAuth.disconnect_sessions(expired_tokens)

      conn
      |> put_session(:user_return_to, ~p"/users/settings")
      |> create(params, gettext("Password updated successfully!"))
    else
      conn
      |> put_flash(
        :error,
        gettext("Your session has expired. Please log in again to make changes.")
      )
      |> redirect(to: ~p"/users/log-in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, gettext("Logged out successfully."))
    |> UserAuth.log_out_user()
  end

  # Generates a personalized welcome message using the user's first name
  # or email prefix if no first name is set. Shows "Welcome" for first-time
  # logins and "Welcome back" for returning users.
  defp welcome_message(user) do
    name = get_display_name(user) |> capitalize_name()

    # Check if this is the user's first login by checking if they confirmed recently (within 5 minutes)
    # This indicates they just registered and confirmed their account
    is_first_login =
      if user.confirmed_at do
        DateTime.diff(DateTime.utc_now(), user.confirmed_at, :minute) < 5
      else
        false
      end

    if is_first_login do
      gettext("Welcome %{name}!", name: name)
    else
      gettext("Welcome back %{name}!", name: name)
    end
  end

  defp get_display_name(%{first_name: first_name})
       when is_binary(first_name) and first_name != "" do
    first_name
  end

  defp get_display_name(%{email: email}) when is_binary(email) do
    email
    |> String.split("@")
    |> List.first()
  end

  defp get_display_name(_user), do: ""

  # Capitalizes the first letter of the name (e.g., "mipa" -> "Mipa")
  defp capitalize_name(""), do: ""
  defp capitalize_name(name), do: String.capitalize(name)
end

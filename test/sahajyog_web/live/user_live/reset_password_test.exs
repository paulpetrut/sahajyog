defmodule SahajyogWeb.UserLive.ResetPasswordTest do
  use SahajyogWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Sahajyog.AccountsFixtures

  alias Sahajyog.Accounts
  alias Sahajyog.Accounts.UserToken
  alias Sahajyog.Repo

  describe "reset password page with valid token" do
    setup do
      user = user_fixture() |> set_password()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_password_reset_instructions(user.email, url)
        end)

      %{user: user, token: token}
    end

    test "renders reset password form", %{conn: conn, token: token} do
      {:ok, _lv, html} = live(conn, ~p"/users/reset-password/#{token}")

      assert html =~ "Reset Password"
      assert html =~ "Enter your new password"
      assert html =~ "New password"
      assert html =~ "Confirm new password"
      assert html =~ "Reset password"
    end

    test "has link back to login page", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/users/reset-password/#{token}")

      {:ok, _login_lv, login_html} =
        lv
        |> element("a", "Back to login")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert login_html =~ "Welcome back"
    end
  end

  describe "reset password with invalid token" do
    test "redirects to forgot password page with error for invalid token", %{conn: conn} do
      # When token is invalid, mount redirects immediately
      {:error, {:live_redirect, %{to: to, flash: flash}}} =
        live(conn, ~p"/users/reset-password/invalid-token")

      assert to == "/users/forgot-password"
      assert flash["error"] =~ "Reset password link is invalid or has expired"
    end

    test "redirects for expired token", %{conn: conn} do
      user = user_fixture() |> set_password()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_password_reset_instructions(user.email, url)
        end)

      # Expire the token by setting inserted_at to more than 60 minutes ago
      Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])

      {:error, {:live_redirect, %{to: to, flash: flash}}} =
        live(conn, ~p"/users/reset-password/#{token}")

      assert to == "/users/forgot-password"
      assert flash["error"] =~ "Reset password link is invalid or has expired"
    end

    test "redirects for already-used token", %{conn: conn} do
      user = user_fixture() |> set_password()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_password_reset_instructions(user.email, url)
        end)

      # Use the token to reset password
      {:ok, _user} = Accounts.reset_user_password(user, %{password: "newpassword123"})

      # Try to use the token again - should redirect immediately
      {:error, {:live_redirect, %{to: to, flash: flash}}} =
        live(conn, ~p"/users/reset-password/#{token}")

      assert to == "/users/forgot-password"
      assert flash["error"] =~ "Reset password link is invalid or has expired"
    end
  end

  describe "password validation" do
    setup do
      user = user_fixture() |> set_password()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_password_reset_instructions(user.email, url)
        end)

      %{user: user, token: token}
    end

    test "shows error for password too short", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/users/reset-password/#{token}")

      html =
        lv
        |> form("#reset_password_form",
          user: %{password: "short", password_confirmation: "short"}
        )
        |> render_change()

      assert html =~ "should be at least 12 character"
    end

    test "shows error for password mismatch", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/users/reset-password/#{token}")

      html =
        lv
        |> form("#reset_password_form",
          user: %{password: "validpassword123", password_confirmation: "differentpassword"}
        )
        |> render_change()

      assert html =~ "does not match password"
    end

    test "accepts valid password on change", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/users/reset-password/#{token}")

      html =
        lv
        |> form("#reset_password_form",
          user: %{password: "validpassword123", password_confirmation: "validpassword123"}
        )
        |> render_change()

      refute html =~ "should be at least 12 character"
      refute html =~ "does not match password"
    end
  end

  describe "successful password reset" do
    setup do
      user = user_fixture() |> set_password()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_password_reset_instructions(user.email, url)
        end)

      %{user: user, token: token}
    end

    test "resets password and redirects to login", %{conn: conn, user: user, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/users/reset-password/#{token}")

      {:ok, login_lv, _login_html} =
        lv
        |> form("#reset_password_form",
          user: %{password: "newvalidpassword", password_confirmation: "newvalidpassword"}
        )
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert render(login_lv) =~ "Password reset successfully"

      # Verify the new password works
      assert Accounts.get_user_by_email_and_password(user.email, "newvalidpassword")
    end

    test "invalidates all sessions after reset", %{conn: conn, user: user, token: token} do
      # Create a session token
      session_token = Accounts.generate_user_session_token(user)
      assert Accounts.get_user_by_session_token(session_token)

      {:ok, lv, _html} = live(conn, ~p"/users/reset-password/#{token}")

      {:ok, _login_lv, _login_html} =
        lv
        |> form("#reset_password_form",
          user: %{password: "newvalidpassword", password_confirmation: "newvalidpassword"}
        )
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log-in")

      # Session token should be invalidated
      refute Accounts.get_user_by_session_token(session_token)
    end

    test "token cannot be reused after successful reset", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/users/reset-password/#{token}")

      {:ok, _login_lv, _login_html} =
        lv
        |> form("#reset_password_form",
          user: %{password: "newvalidpassword", password_confirmation: "newvalidpassword"}
        )
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log-in")

      # Try to use the same token again - should redirect immediately
      {:error, {:live_redirect, %{to: to, flash: flash}}} =
        live(conn, ~p"/users/reset-password/#{token}")

      assert to == "/users/forgot-password"
      assert flash["error"] =~ "Reset password link is invalid or has expired"
    end
  end
end

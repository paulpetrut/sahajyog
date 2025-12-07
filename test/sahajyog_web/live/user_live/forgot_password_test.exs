defmodule SahajyogWeb.UserLive.ForgotPasswordTest do
  use SahajyogWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Sahajyog.AccountsFixtures

  alias Sahajyog.Accounts.UserToken
  alias Sahajyog.Repo

  describe "forgot password page" do
    test "renders forgot password page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/forgot-password")

      assert html =~ "Forgot your password?"
      assert html =~ "Enter your email"
      assert html =~ "Send reset instructions"
      assert html =~ "Back to login"
    end

    test "has link back to login page", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/forgot-password")

      {:ok, _login_lv, login_html} =
        lv
        |> element("a", "Back to login")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert login_html =~ "Welcome back"
    end
  end

  describe "forgot password form submission" do
    test "sends reset email when user exists with password", %{conn: conn} do
      user = user_fixture() |> set_password()

      {:ok, lv, _html} = live(conn, ~p"/users/forgot-password")

      {:ok, login_lv, login_html} =
        lv
        |> form("#forgot_password_form", user: %{email: user.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log-in")

      # Verify we're on the login page with flash message
      assert login_html =~ "Welcome back"
      assert render(login_lv) =~ "If your email is in our system"

      # Verify token was created
      assert token = Repo.get_by(UserToken, user_id: user.id, context: "reset_password")
      assert token.sent_to == user.email
    end

    test "shows same success message for non-existent email (prevents enumeration)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/forgot-password")

      {:ok, login_lv, _login_html} =
        lv
        |> form("#forgot_password_form", user: %{email: "nonexistent@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert render(login_lv) =~ "If your email is in our system"
    end

    test "shows same success message for user without password", %{conn: conn} do
      # Create user without password (passwordless user)
      user = user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/users/forgot-password")

      {:ok, login_lv, _login_html} =
        lv
        |> form("#forgot_password_form", user: %{email: user.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert render(login_lv) =~ "If your email is in our system"

      # Verify no token was created for passwordless user
      refute Repo.get_by(UserToken, user_id: user.id, context: "reset_password")
    end

    test "redirects to login with success message after submission", %{conn: conn} do
      user = user_fixture() |> set_password()

      {:ok, lv, _html} = live(conn, ~p"/users/forgot-password")

      {:ok, login_lv, login_html} =
        lv
        |> form("#forgot_password_form", user: %{email: user.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert login_html =~ "Welcome back"
      assert render(login_lv) =~ "If your email is in our system"
    end
  end

  describe "forgot password validation" do
    test "shows error for empty email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/forgot-password")

      html =
        lv
        |> form("#forgot_password_form", user: %{email: ""})
        |> render_submit()

      assert html =~ "must be a valid email address"
    end

    test "shows error for whitespace-only email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/forgot-password")

      html =
        lv
        |> form("#forgot_password_form", user: %{email: "   "})
        |> render_submit()

      assert html =~ "must be a valid email address"
    end

    test "shows error for email without @", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/forgot-password")

      html =
        lv
        |> form("#forgot_password_form", user: %{email: "notanemail"})
        |> render_submit()

      assert html =~ "must be a valid email address"
    end

    test "shows error for email with spaces", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/forgot-password")

      html =
        lv
        |> form("#forgot_password_form", user: %{email: "test user@example.com"})
        |> render_submit()

      assert html =~ "must be a valid email address"
    end
  end

  describe "login page has forgot password link" do
    test "login page contains forgot password link", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/log-in")

      assert html =~ "Forgot password?"
      assert html =~ ~p"/users/forgot-password"
    end

    test "can navigate from login to forgot password", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      {:ok, _forgot_lv, forgot_html} =
        lv
        |> element("a", "Forgot password?")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/forgot-password")

      assert forgot_html =~ "Forgot your password?"
    end
  end
end

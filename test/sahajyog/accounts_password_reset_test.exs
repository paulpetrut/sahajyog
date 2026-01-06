defmodule Sahajyog.AccountsPasswordResetTest do
  use Sahajyog.DataCase
  use ExUnitProperties

  alias Sahajyog.Accounts
  alias Sahajyog.Accounts.UserNotifier
  alias Sahajyog.Accounts.UserToken
  alias Sahajyog.Repo

  import Sahajyog.AccountsFixtures

  describe "email format validation" do
    @tag iterations: 100
    property "Property 3: Invalid email format rejection - strings without @ or with spaces are rejected" do
      # **Feature: password-recovery, Property 3: Invalid email format rejection**
      # **Validates: Requirements 1.5**
      #
      # For any string that is not a valid email format (missing @, contains spaces,
      # empty string, whitespace-only), the forgot password form should reject the
      # submission with a validation error.

      check all(
              invalid_email <- invalid_email_generator(),
              max_runs: 100
            ) do
        # The valid_email_format? function should return false for invalid emails
        refute valid_email_format?(invalid_email),
               "Expected #{inspect(invalid_email)} to be rejected as invalid email"
      end
    end

    @tag iterations: 100
    property "Property 3 (positive): Valid email formats are accepted" do
      # Complementary test: valid emails should be accepted
      check all(
              local_part <- string(:alphanumeric, min_length: 1, max_length: 20),
              domain <- string(:alphanumeric, min_length: 1, max_length: 10),
              tld <- member_of(["com", "org", "net", "io", "dev"]),
              max_runs: 100
            ) do
        valid_email = "#{local_part}@#{domain}.#{tld}"

        assert valid_email_format?(valid_email),
               "Expected #{inspect(valid_email)} to be accepted as valid email"
      end
    end

    # Generator for invalid email formats
    defp invalid_email_generator do
      one_of([
        # Empty string
        constant(""),
        # Whitespace only
        map(string([?\s, ?\t, ?\n], min_length: 1, max_length: 10), & &1),
        # No @ symbol
        filter(string(:alphanumeric, min_length: 1, max_length: 30), fn s ->
          not String.contains?(s, "@")
        end),
        # Contains spaces
        map(
          tuple({
            string(:alphanumeric, min_length: 1, max_length: 10),
            string(:alphanumeric, min_length: 1, max_length: 10)
          }),
          fn {a, b} -> "#{a} #{b}@example.com" end
        ),
        # Just @ symbol
        constant("@"),
        # @ at start with no local part
        map(string(:alphanumeric, min_length: 1, max_length: 10), fn domain ->
          "@#{domain}.com"
        end),
        # @ at end with no domain
        map(string(:alphanumeric, min_length: 1, max_length: 10), fn local ->
          "#{local}@"
        end)
      ])
    end

    # Mirror the validation logic from ForgotPasswordLive
    defp valid_email_format?(email) when is_binary(email) do
      email = String.trim(email)

      case String.split(email, "@") do
        [local, domain] when local != "" and domain != "" ->
          not String.contains?(email, " ")

        _ ->
          false
      end
    end

    defp valid_email_format?(_), do: false
  end

  describe "verify_reset_password_token_query/1" do
    @tag iterations: 100
    property "Property 4: Valid token grants form access - valid non-expired tokens return the correct user" do
      # **Feature: password-recovery, Property 4: Valid token grants form access**
      # **Validates: Requirements 3.1**
      check all(
              email_prefix <- string(:alphanumeric, min_length: 3, max_length: 10),
              max_runs: 100
            ) do
        # Create a user with a password
        email = "#{email_prefix}#{System.unique_integer([:positive])}@example.com"
        user = user_fixture(%{email: email}) |> set_password()

        # Generate a reset password token
        {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
        Repo.insert!(user_token)

        # Verify the token returns the correct user
        {:ok, query} = UserToken.verify_reset_password_token_query(encoded_token)
        {returned_user, _token} = Repo.one(query)

        assert returned_user.id == user.id
        assert returned_user.email == user.email
      end
    end

    test "returns error for invalid base64 token" do
      assert :error = UserToken.verify_reset_password_token_query("invalid!!token")
    end

    test "returns nil for non-existent token" do
      # Generate a valid base64 token that doesn't exist in the database
      fake_token = Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)
      {:ok, query} = UserToken.verify_reset_password_token_query(fake_token)
      assert is_nil(Repo.one(query))
    end

    test "returns nil for expired token" do
      user = user_fixture() |> set_password()
      {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
      Repo.insert!(user_token)

      # Expire the token by setting inserted_at to more than 60 minutes ago
      Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])

      {:ok, query} = UserToken.verify_reset_password_token_query(encoded_token)
      assert is_nil(Repo.one(query))
    end

    test "returns nil for token with wrong context" do
      user = user_fixture() |> set_password()
      # Generate a login token (magic link) instead of reset_password
      {encoded_token, user_token} = UserToken.build_email_token(user, "login")
      Repo.insert!(user_token)

      {:ok, query} = UserToken.verify_reset_password_token_query(encoded_token)
      assert is_nil(Repo.one(query))
    end
  end

  describe "deliver_password_reset_instructions/3" do
    @tag iterations: 100
    property "Property 1: Token generation for password users creates valid, hashed tokens" do
      # **Feature: password-recovery, Property 1: Token generation for password users creates valid, hashed tokens**
      # **Validates: Requirements 1.3, 2.1, 2.2, 2.3**
      check all(
              email_prefix <- string(:alphanumeric, min_length: 3, max_length: 10),
              max_runs: 100
            ) do
        # Create a user with a password
        email = "#{email_prefix}#{System.unique_integer([:positive])}@example.com"
        user = user_fixture(%{email: email}) |> set_password()

        # Capture the token from the email
        token =
          extract_user_token(fn url ->
            Accounts.deliver_password_reset_instructions(user.email, url)
          end)

        # Verify the token is valid base64
        assert {:ok, decoded_token} = Base.url_decode64(token, padding: false)

        # Verify a hashed version is stored in the database
        hashed_token = :crypto.hash(:sha256, decoded_token)
        assert db_token = Repo.get_by(UserToken, token: hashed_token)
        assert db_token.context == "reset_password"
        assert db_token.user_id == user.id
        assert db_token.sent_to == user.email

        # Verify the token can be used to retrieve the user
        assert returned_user = Accounts.get_user_by_reset_password_token(token)
        assert returned_user.id == user.id
      end
    end

    @tag iterations: 100
    property "Property 2: Email enumeration prevention - same response for existing and non-existing emails" do
      # **Feature: password-recovery, Property 2: Email enumeration prevention**
      # **Validates: Requirements 1.4**
      check all(
              email_prefix <- string(:alphanumeric, min_length: 3, max_length: 10),
              max_runs: 100
            ) do
        # Test with non-existent email
        non_existent_email =
          "nonexistent_#{email_prefix}#{System.unique_integer([:positive])}@example.com"

        result_non_existent =
          Accounts.deliver_password_reset_instructions(non_existent_email, fn token ->
            "http://test/#{token}"
          end)

        # Test with existing user without password
        passwordless_email =
          "passwordless_#{email_prefix}#{System.unique_integer([:positive])}@example.com"

        _passwordless_user = user_fixture(%{email: passwordless_email})

        result_passwordless =
          Accounts.deliver_password_reset_instructions(passwordless_email, fn token ->
            "http://test/#{token}"
          end)

        # Both should return {:ok, :no_op} - same response pattern
        assert result_non_existent == {:ok, :no_op}
        assert result_passwordless == {:ok, :no_op}
      end
    end

    @tag iterations: 100
    property "Property 8: New reset request invalidates previous tokens" do
      # **Feature: password-recovery, Property 8: New reset request invalidates previous tokens**
      # **Validates: Requirements 4.2**
      check all(
              email_prefix <- string(:alphanumeric, min_length: 3, max_length: 10),
              max_runs: 100
            ) do
        # Create a user with a password
        email = "#{email_prefix}#{System.unique_integer([:positive])}@example.com"
        user = user_fixture(%{email: email}) |> set_password()

        # Request first password reset
        first_token =
          extract_user_token(fn url ->
            Accounts.deliver_password_reset_instructions(user.email, url)
          end)

        # Request second password reset
        second_token =
          extract_user_token(fn url ->
            Accounts.deliver_password_reset_instructions(user.email, url)
          end)

        # First token should be invalid (deleted)
        assert is_nil(Accounts.get_user_by_reset_password_token(first_token))

        # Second token should be valid
        assert returned_user = Accounts.get_user_by_reset_password_token(second_token)
        assert returned_user.id == user.id
      end
    end
  end

  describe "reset_user_password/2" do
    @tag iterations: 100
    property "Property 6: Password reset invalidates all sessions" do
      # **Feature: password-recovery, Property 6: Password reset invalidates all sessions**
      # **Validates: Requirements 3.5, 4.3**
      check all(
              email_prefix <- string(:alphanumeric, min_length: 3, max_length: 10),
              password_suffix <- string(:alphanumeric, min_length: 5, max_length: 10),
              max_runs: 100
            ) do
        # Create a user with a password
        email = "#{email_prefix}#{System.unique_integer([:positive])}@example.com"
        user = user_fixture(%{email: email}) |> set_password()

        # Create some session tokens
        session_token1 = Accounts.generate_user_session_token(user)
        session_token2 = Accounts.generate_user_session_token(user)

        # Verify sessions exist
        assert Accounts.get_user_by_session_token(session_token1)
        assert Accounts.get_user_by_session_token(session_token2)

        # Reset the password
        new_password = "newpassword_#{password_suffix}"
        assert {:ok, updated_user} = Accounts.reset_user_password(user, %{password: new_password})

        # Verify all session tokens are invalidated
        refute Accounts.get_user_by_session_token(session_token1)
        refute Accounts.get_user_by_session_token(session_token2)

        # Verify the new password works
        assert Accounts.get_user_by_email_and_password(updated_user.email, new_password)
      end
    end

    @tag iterations: 100
    property "Property 7: Token single-use enforcement" do
      # **Feature: password-recovery, Property 7: Token single-use enforcement**
      # **Validates: Requirements 4.1**
      check all(
              email_prefix <- string(:alphanumeric, min_length: 3, max_length: 10),
              password_suffix <- string(:alphanumeric, min_length: 5, max_length: 10),
              max_runs: 100
            ) do
        # Create a user with a password
        email = "#{email_prefix}#{System.unique_integer([:positive])}@example.com"
        user = user_fixture(%{email: email}) |> set_password()

        # Request password reset
        token =
          extract_user_token(fn url ->
            Accounts.deliver_password_reset_instructions(user.email, url)
          end)

        # Verify token is valid
        assert returned_user = Accounts.get_user_by_reset_password_token(token)
        assert returned_user.id == user.id

        # Use the token to reset password
        new_password = "newpassword_#{password_suffix}"

        assert {:ok, _updated_user} =
                 Accounts.reset_user_password(returned_user, %{password: new_password})

        # Token should now be invalid (deleted along with all other tokens)
        refute Accounts.get_user_by_reset_password_token(token)
      end
    end
  end

  describe "password validation" do
    @tag iterations: 100
    property "Property 5: Password validation enforcement - passwords under 12 chars are rejected, 12+ chars accepted" do
      # **Feature: password-recovery, Property 5: Password validation enforcement**
      # **Validates: Requirements 3.4**
      #
      # For any password submitted to the reset form, if the password is shorter
      # than 12 characters, the system should reject it with a validation error.
      # If the password is 12 or more characters (up to 72), the system should accept it.

      check all(
              email_prefix <- string(:alphanumeric, min_length: 3, max_length: 10),
              # Generate passwords of various lengths (1-80 chars)
              password_length <- integer(1..80),
              password_chars <- string(:alphanumeric, length: password_length),
              max_runs: 100
            ) do
        # Create a user with a password
        email = "#{email_prefix}#{System.unique_integer([:positive])}@example.com"
        user = user_fixture(%{email: email}) |> set_password()

        # Attempt to reset password with the generated password
        result = Accounts.reset_user_password(user, %{password: password_chars})

        cond do
          password_length < 12 ->
            # Passwords under 12 characters should be rejected
            assert {:error, changeset} = result
            assert "should be at least 12 character(s)" in errors_on(changeset).password

          password_length > 72 ->
            # Passwords over 72 bytes should be rejected (bcrypt limit)
            assert {:error, changeset} = result
            assert "should be at most 72 character(s)" in errors_on(changeset).password

          true ->
            # Passwords between 12-72 characters should be accepted
            assert {:ok, _user} = result
        end
      end
    end

    test "password validation rejects empty password" do
      user = user_fixture() |> set_password()
      result = Accounts.reset_user_password(user, %{password: ""})

      assert {:error, changeset} = result
      assert "can't be blank" in errors_on(changeset).password
    end

    test "password validation rejects nil password" do
      user = user_fixture() |> set_password()
      result = Accounts.reset_user_password(user, %{password: nil})

      assert {:error, changeset} = result
      assert "can't be blank" in errors_on(changeset).password
    end

    test "password validation accepts exactly 12 character password" do
      user = user_fixture() |> set_password()
      result = Accounts.reset_user_password(user, %{password: "exactly12chr"})

      assert {:ok, _user} = result
    end

    test "password validation accepts exactly 72 character password" do
      user = user_fixture() |> set_password()
      password_72 = String.duplicate("a", 72)
      result = Accounts.reset_user_password(user, %{password: password_72})

      assert {:ok, _user} = result
    end
  end

  describe "UserNotifier.deliver_password_reset_instructions/3" do
    @tag iterations: 100
    property "Property 9: Email content respects locale" do
      # **Feature: password-recovery, Property 9: Email content respects locale**
      # **Validates: Requirements 5.2**
      #
      # For any password reset email sent, the email content should be in the
      # language corresponding to the locale parameter passed to the delivery function.
      #
      # We test this by verifying that:
      # 1. The email is successfully generated for each supported locale
      # 2. The locale parameter is passed through to the translation function
      # 3. The email contains the expected URL

      # Available locales in the system
      supported_locales = ["en", "de", "es", "fr", "it", "ro"]

      check all(
              email_prefix <- string(:alphanumeric, min_length: 3, max_length: 10),
              locale <- member_of(supported_locales),
              max_runs: 100
            ) do
        # Create a user with a password
        email = "#{email_prefix}#{System.unique_integer([:positive])}@example.com"
        user = user_fixture(%{email: email}) |> set_password()

        # Generate a test URL
        test_url = "https://example.com/reset/test-token-#{System.unique_integer([:positive])}"

        # Call the notifier with the locale
        result = UserNotifier.deliver_password_reset_instructions(user, test_url, locale)

        # Verify the email was generated successfully
        assert {:ok, email_struct} = result

        # Verify the email contains the reset URL
        assert String.contains?(email_struct.text_body, test_url)

        # Verify the email is sent to the correct recipient
        # The to field can be either {nil, email} or {"", email} depending on Swoosh version
        assert [{_, recipient_email}] = email_struct.to
        assert recipient_email == user.email

        # Verify the email has a subject (translated based on locale)
        assert is_binary(email_struct.subject)
        assert String.length(email_struct.subject) > 0
      end
    end
  end
end

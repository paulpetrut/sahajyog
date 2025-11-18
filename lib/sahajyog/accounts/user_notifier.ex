defmodule Sahajyog.Accounts.UserNotifier do
  import Swoosh.Email

  alias Sahajyog.Mailer
  alias Sahajyog.Accounts.User

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    from_email = System.get_env("FROM_EMAIL") || "noreply@sahajaonline.xyz"
    from_name = System.get_env("FROM_NAME") || "SahajYog"

    email =
      new()
      |> to(recipient)
      |> from({from_name, from_email})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    deliver(user.email, "Your SahajYog Login Link", """

    Hello,

    You requested a secure login link for your SahajYog account.

    Click the link below to log in:

    #{url}

    This link will expire in 1 hour for security reasons.

    If you didn't request this, you can safely ignore this email.

    Best regards,
    The SahajYog Team
    """)
  end

  defp deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Welcome to SahajYog - Confirm Your Account", """

    Welcome to SahajYog!

    Thank you for registering. To complete your registration and access your account,
    please confirm your email address by clicking the link below:

    #{url}

    This link will expire in 24 hours for security reasons.

    If you didn't create an account with us, you can safely ignore this email.

    Best regards,
    The SahajYog Team
    """)
  end
end

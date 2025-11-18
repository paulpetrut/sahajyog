defmodule Sahajyog.Accounts.UserNotifier do
  import Swoosh.Email

  alias Sahajyog.Mailer
  alias Sahajyog.Accounts.User

  # Helper to translate strings with the given locale
  defp t(msgid, locale) do
    Gettext.with_locale(SahajyogWeb.Gettext, locale, fn ->
      Gettext.dgettext(SahajyogWeb.Gettext, "default", msgid)
    end)
  end

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
  def deliver_update_email_instructions(user, url, locale \\ "en") do
    subject = t("Update email instructions", locale)

    body = """

    ==============================

    #{t("Hi", locale)} #{user.email},

    #{t("You can change your email by visiting the URL below:", locale)}

    #{url}

    #{t("If you didn't request this change, please ignore this.", locale)}

    ==============================
    """

    deliver(user.email, subject, body)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url, locale \\ "en") do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url, locale)
      _ -> deliver_magic_link_instructions(user, url, locale)
    end
  end

  defp deliver_magic_link_instructions(user, url, locale) do
    subject = t("Your SahajYog Login Link", locale)

    body = """

    #{t("Hello", locale)},

    #{t("You requested a secure login link for your SahajYog account.", locale)}

    #{t("Click the link below to log in:", locale)}

    #{url}

    #{t("This link will expire in 1 hour for security reasons.", locale)}

    #{t("If you didn't request this, you can safely ignore this email.", locale)}

    #{t("Best regards", locale)},
    #{t("The SahajYog Team", locale)}
    """

    deliver(user.email, subject, body)
  end

  defp deliver_confirmation_instructions(user, url, locale) do
    subject = t("Welcome to SahajYog - Confirm Your Account", locale)

    body = """

    #{t("Welcome to SahajYog!", locale)}

    #{t("Thank you for registering. To complete your registration and access your account, please confirm your email address by clicking the link below:", locale)}

    #{url}

    #{t("This link will expire in 24 hours for security reasons.", locale)}

    #{t("If you didn't create an account with us, you can safely ignore this email.", locale)}

    #{t("Best regards", locale)},
    #{t("The SahajYog Team", locale)}
    """

    deliver(user.email, subject, body)
  end
end

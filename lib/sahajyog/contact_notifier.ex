defmodule Sahajyog.ContactNotifier do
  @moduledoc """
  Handles sending contact form emails.
  """
  import Swoosh.Email

  alias Sahajyog.Mailer

  @doc """
  Sends a contact form submission to the admin email.
  """
  def deliver_contact_message(name, email, subject, message) do
    require Logger
    from_email = System.get_env("FROM_EMAIL") || "noreply@sahajaonline.xyz"
    from_name = System.get_env("FROM_NAME") || "SahajYog"
    admin_email = System.get_env("CONTACT_EMAIL") || "itblast33@gmail.com"

    Logger.info("Sending contact form submission from #{email}")

    body = """
    New contact form submission:

    Name: #{name}
    Email: #{email}
    Subject: #{subject}

    Message:
    #{message}

    ---
    This message was sent via the SahajYog contact form.
    """

    email =
      new()
      |> to(admin_email)
      |> from({from_name, from_email})
      |> reply_to(email)
      |> subject("Contact Form: #{subject}")
      |> text_body(body)

    case Mailer.deliver(email) do
      {:ok, _metadata} ->
        Logger.info("Contact form email sent successfully")
        {:ok, email}

      {:error, reason} = error ->
        Logger.error("Failed to send contact form email: #{inspect(reason)}")
        error
    end
  end
end

defmodule Sahajyog.Events.EventNotifier do
  @moduledoc """
  Notifies users about event-related actions via email.
  """
  import Swoosh.Email
  alias Sahajyog.Mailer
  require Logger

  def deliver_contact_email(recipients, sender_email, sender_name, event_title, message) do
    subject = "[SahajYog] Inquiry about: #{event_title}"

    from_email = System.get_env("FROM_EMAIL") || "noreply@sahajaonline.xyz"
    from_name = System.get_env("FROM_NAME") || "SahajYog Events"

    body = """
    You have received a new message regarding your event "#{event_title}".

    From: #{sender_name} (#{sender_email})

    Message:
    #{message}

    -------------------------------------------
    You can reply directly to this email to contact the sender.
    """

    Enum.each(recipients, fn recipient ->
      email =
        new()
        |> to(recipient)
        |> from({from_name, from_email})
        |> reply_to({sender_name, sender_email})
        |> subject(subject)
        |> text_body(body)

      case Mailer.deliver(email) do
        {:ok, _} ->
          Logger.info("Contact email sent to #{recipient}")

        {:error, reason} ->
          Logger.error("Failed to send contact email to #{recipient}: #{inspect(reason)}")
      end
    end)
  end

  def deliver_invitation_email(to, event_title, invited_by_name, accept_url, reject_url) do
    if !url_valid?(accept_url) || !url_valid?(reject_url) do
      raise ArgumentError, "acceptance URLs must be fully qualified URLs"
    end

    deliver(to, "Invitation to co-own event: #{event_title}", """
    Hello,

    #{invited_by_name} has invited you to be a co-owner of the event "#{event_title}".

    As a co-owner, you will be able to edit event details, manage tasks, and invite other team members.

    To accept this invitation, please visit the event page:
    If you wish to decline, you can also do so from the event page.
    """)
  end

  def deliver_team_removal_email(to, event_title) do
    deliver(to, "You have been removed from event: #{event_title}", """
    Hello,

    You have been removed from the team for the event "#{event_title}".

    You no longer have access to edit this event or manage its team.

    If you believe this is an error, please contact the event owner directly.
    """)
  end

  defp deliver(to, subject, body) do
    from_email = System.get_env("FROM_EMAIL") || "noreply@sahajaonline.xyz"
    from_name = System.get_env("FROM_NAME") || "SahajYog Events"

    email =
      new()
      |> to(to)
      |> from({from_name, from_email})
      |> subject(subject)
      |> text_body(body)

    case Mailer.deliver(email) do
      {:ok, _} ->
        Logger.info("Email sent to #{to}")

      {:error, reason} ->
        Logger.error("Failed to send email to #{to}: #{inspect(reason)}")
    end
  end

  defp url_valid?(url) do
    uri = URI.parse(url)
    uri.scheme != nil && uri.host != nil
  end
end

defmodule Sahajyog.Store.StoreNotifier do
  @moduledoc """
  Handles sending email notifications for SahajStore marketplace events.
  """
  import Swoosh.Email

  alias Sahajyog.Mailer
  require Logger

  @doc """
  Delivers an email notification when a store item is approved.
  """
  def deliver_item_approved(item, seller) do
    subject = "[SahajStore] Your item has been approved: #{item.name}"

    body = """
    Hello #{seller.first_name},

    Great news! Your store item "#{item.name}" has been approved and is now visible on SahajStore.

    Item Details:
    - Name: #{item.name}
    - Quantity: #{item.quantity}
    - Pricing: #{format_pricing(item)}

    Buyers can now view your listing and contact you with inquiries.

    Thank you for contributing to our community marketplace!

    Best regards,
    The SahajYog Team
    """

    deliver(seller.email, subject, body)
  end

  @doc """
  Delivers an email notification when a store item is rejected.
  """
  def deliver_item_rejected(item, seller, review_notes) do
    subject = "[SahajStore] Your item requires changes: #{item.name}"

    body = """
    Hello #{seller.first_name},

    Your store item "#{item.name}" was not approved for listing on SahajStore.

    Reviewer Notes:
    #{review_notes}

    You can edit your item and resubmit it for review. Once you make the necessary changes, your item will be reviewed again.

    If you have any questions, please contact us.

    Best regards,
    The SahajYog Team
    """

    deliver(seller.email, subject, body)
  end

  @doc """
  Delivers an inquiry notification to the seller.
  """
  def deliver_inquiry_to_seller(inquiry, item, seller, buyer) do
    subject = "[SahajStore] New inquiry for: #{item.name}"

    body = """
    Hello #{seller.first_name},

    You have received a new inquiry for your store item "#{item.name}".

    Buyer Information:
    - Name: #{buyer.first_name} #{buyer.last_name}
    - Email: #{buyer.email}
    - Requested Quantity: #{inquiry.requested_quantity}

    Message:
    #{inquiry.message}

    ---
    You can reply directly to this email to contact the buyer.

    Best regards,
    The SahajYog Team
    """

    deliver_with_reply_to(seller.email, subject, body, buyer.email)
  end

  # Private helper to deliver email
  defp deliver(to, subject, body) do
    from_email = System.get_env("FROM_EMAIL") || "noreply@sahajaonline.xyz"
    from_name = System.get_env("FROM_NAME") || "SahajStore"

    email =
      new()
      |> to(to)
      |> from({from_name, from_email})
      |> subject(subject)
      |> text_body(body)

    case Mailer.deliver(email) do
      {:ok, _metadata} ->
        Logger.info("Email sent successfully to #{to}")
        {:ok, email}

      {:error, reason} = error ->
        Logger.error("Failed to send email to #{to}: #{inspect(reason)}")
        error
    end
  end

  # Private helper to deliver email with reply-to header
  defp deliver_with_reply_to(to, subject, body, reply_to_email) do
    from_email = System.get_env("FROM_EMAIL") || "noreply@sahajaonline.xyz"
    from_name = System.get_env("FROM_NAME") || "SahajStore"

    email =
      new()
      |> to(to)
      |> from({from_name, from_email})
      |> reply_to(reply_to_email)
      |> subject(subject)
      |> text_body(body)

    case Mailer.deliver(email) do
      {:ok, _metadata} ->
        Logger.info("Email sent successfully to #{to}")
        {:ok, email}

      {:error, reason} = error ->
        Logger.error("Failed to send email to #{to}: #{inspect(reason)}")
        error
    end
  end

  # Format pricing for display
  defp format_pricing(%{pricing_type: "fixed_price", price: price, currency: currency}) do
    symbol = Sahajyog.Store.StoreItem.currency_symbol(currency)
    "Fixed Price - #{symbol}#{price}"
  end

  defp format_pricing(%{pricing_type: "accepts_donation"}) do
    "Accepts Donation"
  end

  defp format_pricing(_), do: "Not specified"
end

defmodule Sahajyog.EventFinance do
  @moduledoc """
  Context for managing event donations and financial tracking.
  """

  import Ecto.Query
  alias Sahajyog.Events.EventDonation
  alias Sahajyog.Repo

  @doc """
  Lists donations for an event.
  """
  def list_donations(event_id) do
    EventDonation
    |> where([d], d.event_id == ^event_id)
    |> order_by([d], desc: d.payment_date, desc: d.inserted_at)
    |> preload([:donor_user, :recorded_by])
    |> Repo.all()
  end

  @doc """
  Creates a donation record.
  """
  def create_donation(current_scope, event_id, attrs) do
    attrs =
      attrs
      |> Map.put("event_id", event_id)
      |> Map.put("recorded_by_id", current_scope.user.id)

    %EventDonation{}
    |> EventDonation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a donation record.
  """
  def update_donation(%EventDonation{} = donation, attrs) do
    donation
    |> EventDonation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a donation record.
  """
  def delete_donation(%EventDonation{} = donation) do
    Repo.delete(donation)
  end

  @doc """
  Returns a changeset for tracking donation changes.
  """
  def change_donation(%EventDonation{} = donation, attrs \\ %{}) do
    EventDonation.changeset(donation, attrs)
  end

  @doc """
  Calculates the total donations for an event.
  """
  def total_donations(event_id) do
    EventDonation
    |> where([d], d.event_id == ^event_id)
    |> select([d], sum(d.amount))
    |> Repo.one() || Decimal.new(0)
  end

  @doc """
  Calculates the total actual expenses from tasks.
  """
  def total_expenses(event_id) do
    from(t in Sahajyog.Events.EventTask,
      where: t.event_id == ^event_id and not is_nil(t.actual_expense),
      select: sum(t.actual_expense)
    )
    |> Repo.one() || Decimal.new(0)
  end

  @doc """
  Generates a financial summary for the event.
  """
  def financial_summary(event_id) do
    event = Repo.get!(Sahajyog.Events.Event, event_id)

    income = total_donations(event_id)
    expenses = total_expenses(event_id)
    balance = Decimal.sub(income, expenses)

    is_profit = Decimal.compare(balance, 0) != :lt

    # Calculate budget progress if budget_total is set
    {budget_progress, budget_remaining} =
      if event.budget_total && Decimal.compare(event.budget_total, 0) == :gt do
        progress =
          income
          |> Decimal.div(event.budget_total)
          |> Decimal.mult(100)
          |> Decimal.round(1)

        remaining = Decimal.sub(event.budget_total, income)
        {progress, remaining}
      else
        {nil, nil}
      end

    %{
      budget_total: event.budget_total,
      budget_type: event.budget_type,
      total_income: income,
      total_expenses: expenses,
      balance: balance,
      is_profit: is_profit,
      budget_progress: budget_progress,
      budget_remaining: budget_remaining
    }
  end
end

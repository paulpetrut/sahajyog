# Financial Tracking Guide

## Overview

The event financial system tracks your event's budget, income (donations), and expenses to give you a complete financial picture.

## How It Works

### 1. Set Your Budget (Event Edit → Finances Tab)

**Location:** Event Edit Page → Finances Tab → Top Section

Set your financial goals:

- **Budget Type**: Choose "Donations" (fundraising) or "Fixed Budget"
- **Total Budget**: Your target amount (e.g., €500)
- **Budget Notes**: Breakdown of what the money is for
- **Banking Info**: Where people can send donations

**Example:**

```
Budget Type: Donations
Total Budget: €500
Budget Notes:
  - Venue rental: €200
  - Catering: €150
  - Materials: €100
  - Contingency: €50
```

### 2. Record Income (Donations)

**Location:** Event Edit Page → Finances Tab → "Donations Received" Section

When someone donates money:

1. Click **"Record Donation"** button
2. Fill in the form:
   - **Amount**: How much they donated (required)
   - **Donor Name**: Who donated (optional, anonymous if blank)
   - **Payment Method**: Bank transfer, cash, or other
   - **Payment Date**: When you received it
   - **Notes**: Any additional info
3. Click **"Save Donation"**

The donation appears in the list and updates your financial summary.

**Example:**

```
Amount: €50
Donor Name: John Smith
Payment Method: Bank Transfer
Payment Date: March 15, 2026
Notes: Donation for venue rental
```

### 3. Track Expenses

**Location:** Event Edit Page → Tasks Tab

Expenses are tracked through tasks:

1. Go to **Tasks** tab
2. Create or edit a task
3. Fill in the **"Actual Expense"** field
4. Save the task

The expense automatically appears in:

- Finances tab → "Expenses (from Tasks)" section
- Financial Summary on the event show page

**Example Task:**

```
Title: Book venue
Description: Reserve meditation hall
Actual Expense: €200
```

### 4. View Financial Summary

**Location:** Event Show Page (public view) → Financial Summary Section

**Visible to:** All attendees (anyone who marked themselves as "attending")

The Financial Summary shows:

#### Budget Progress (if budget is set)

```
┌─────────────────────────────────┐
│ Fundraising Target: €500.00     │
│ Progress: 40.0%                 │
│ [████████░░░░░░░░░░] 40%        │
│ Remaining: €300.00              │
└─────────────────────────────────┘
```

#### Financial Metrics

```
┌─────────────────────────────────┐
│ Income    Expenses  Balance  Donations│
│ €200      €150      €50      4       │
└─────────────────────────────────┘
```

## Complete Workflow Example

### Scenario: Planning a meditation seminar

**Step 1: Set Budget**

- Go to Event Edit → Finances
- Set Budget Type: "Donations"
- Set Total Budget: €500
- Add banking info for donations

**Step 2: Create Tasks with Expenses**

- Go to Tasks tab
- Add task: "Book venue" → Actual Expense: €200
- Add task: "Order catering" → Actual Expense: €150
- Total Expenses: €350

**Step 3: Record Donations**

- Go back to Finances tab
- Record donation: €100 from Maria (bank transfer)
- Record donation: €50 from Anonymous (cash)
- Record donation: €50 from John (bank transfer)
- Total Income: €200

**Step 4: Check Financial Summary**

- Go to event show page
- See: Budget €500, Income €200 (40%), Expenses €350
- Balance: €200 - €350 = -€150 (need more donations!)
- Remaining to reach goal: €300

## Tips

### For Fundraising Events

- Set a realistic budget target
- Record donations promptly
- Share the financial summary with potential donors to show progress
- Update banking info so people know where to donate

### For Fixed Budget Events

- Track all expenses through tasks
- Record any income received
- Monitor balance to stay within budget
- Use budget notes to plan spending

### Best Practices

1. **Record donations immediately** when received
2. **Add expenses to tasks** as you plan them
3. **Update actual expenses** after spending
4. **Check financial summary regularly** to track progress
5. **Use notes fields** to add context for future reference

## Data Flow

```
Event Edit → Finances Tab
├── Budget Settings → Shows in Financial Summary
├── Record Donations → Income in Financial Summary
└── View Donations & Expenses List

Event Edit → Tasks Tab
└── Task Actual Expenses → Expenses in Financial Summary

Event Show Page
└── Financial Summary (Organizers Only)
    ├── Budget Progress Bar
    ├── Income (from donations)
    ├── Expenses (from tasks)
    └── Balance (Income - Expenses)
```

## FAQ

**Q: Where do I enter expenses?**
A: In the Tasks tab. Each task can have an "Actual Expense" field.

**Q: Where do I record donations?**
A: In the Finances tab, click "Record Donation" button.

**Q: Who can see the financial summary?**
A: All attendees (anyone who marked themselves as "attending" the event). Non-attendees cannot see it.

**Q: Why can't I see the financial summary?**
A: You need to mark yourself as "attending" the event first. Also, it's only shown for in-person events (not online events).

**Q: What if I don't set a budget?**
A: The financial summary will still show income, expenses, and balance, but without the progress bar.

**Q: Can I edit or delete donations?**
A: Yes, organizers can click the trash icon next to any donation to delete it.

**Q: How do I track multiple expense categories?**
A: Create separate tasks for each category (venue, catering, materials, etc.) and set their actual expenses.

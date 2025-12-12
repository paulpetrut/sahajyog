# Design Document: Event Level Default Cleanup

## Overview

This design document outlines the cleanup of the event level field to remove redundant `nil` handling. The Event schema already has `default: "Level1"` but queries still check for `is_nil(e.level)` to handle potential legacy data. This cleanup will migrate any existing `nil` values and simplify the query logic.

## Architecture

The change is minimal and focused on data consistency:

```
┌─────────────────────────────────────────────────────────────┐
│                    Before Cleanup                           │
├─────────────────────────────────────────────────────────────┤
│  Event.level can be: "Level1" | "Level2" | "Level3" | NULL  │
│  Query: e.level == "Level1" OR is_nil(e.level)              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    After Cleanup                            │
├─────────────────────────────────────────────────────────────┤
│  Event.level can be: "Level1" | "Level2" | "Level3"         │
│  Query: e.level == "Level1"                                 │
└─────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. Database Migration

Create a migration to convert existing `NULL` level values:

```elixir
def up do
  execute "UPDATE events SET level = 'Level1' WHERE level IS NULL"
end

def down do
  # No rollback needed - Level1 is the correct default
end
```

### 2. Events Module (`lib/sahajyog/events.ex`)

Update `filter_by_level/2` to remove `is_nil` checks:

```elixir
defp filter_by_level(query, level) do
  case level do
    "Level1" -> where(query, [e], e.level == "Level1")
    "Level2" -> where(query, [e], e.level in ["Level1", "Level2"])
    "Level3" -> where(query, [e], e.level in ["Level1", "Level2", "Level3"])
    _ -> where(query, [e], e.level == "Level1")
  end
end
```

### 3. Event Schema (`lib/sahajyog/events/event.ex`)

No changes needed - already has `default: "Level1"`.

## Data Models

### Event Level Field (Updated Constraints)

| Field | Type   | Default  | Nullable | Description           |
| ----- | ------ | -------- | -------- | --------------------- |
| level | string | "Level1" | No\*     | Event visibility tier |

\*After migration, no NULL values will exist. The schema default ensures new events always have a level.

## Correctness Properties

_A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees._

### Property 1: No NULL levels in database

_For any_ event in the database, the level field SHALL NOT be NULL
**Validates: Requirements 1.1, 1.3**

### Property 2-4: Event level filtering (Existing)

The existing property tests in `events_level_test.exs` already validate:

- Level1 users see only Level1 events
- Level2 users see Level1 + Level2 events
- Level3 users see all events

These tests will continue to pass after the cleanup since the behavior is unchanged.

## Error Handling

| Scenario                | Handling                                |
| ----------------------- | --------------------------------------- |
| Migration fails         | Rollback transaction, log error         |
| Unknown level in filter | Default to Level1 filtering (fail-safe) |

## Testing Strategy

### Dual Testing Approach

1. **Unit Tests**: Verify migration converts NULL to Level1
2. **Property-Based Tests**: Verify no NULL levels exist after migration

### Property-Based Testing Framework

We will use **StreamData** (Elixir's built-in property-based testing library).

### Test Categories

#### Unit Tests

- Migration converts NULL levels to "Level1"
- New events without explicit level get "Level1"

#### Property-Based Tests

- **Property 1**: No NULL levels in database (new test)
- **Existing tests**: Event level filtering properties remain unchanged

### Test File Structure

```
test/
├── sahajyog/
│   └── events_level_test.exs    # Add Property 1, existing tests unchanged
```

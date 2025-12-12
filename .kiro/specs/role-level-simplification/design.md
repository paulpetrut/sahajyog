# Design Document: Role and Level Simplification

## Overview

This design document outlines the refactoring of the user authorization model to simplify roles from three values (`admin`, `manager`, `regular`) to two values (`admin`, `user`), and to fix the inverted level hierarchy so that higher levels grant more access (Level3 > Level2 > Level1).

The current system has unused roles (`manager`, `regular`) and a confusing level hierarchy where Level3 users have less content access than Level1 users. This refactoring will create a cleaner, more intuitive authorization model.

## Architecture

The authorization model consists of two orthogonal concepts:

```
┌─────────────────────────────────────────────────────────────┐
│                    User Authorization Model                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐              ┌─────────────────────────┐  │
│  │    ROLE     │              │         LEVEL           │  │
│  │             │              │                         │  │
│  │  admin ─────┼──────────────┼─► Full admin access     │  │
│  │             │              │   (edit any content,    │  │
│  │             │              │    admin panel)         │  │
│  │             │              │                         │  │
│  │  user ──────┼──────────────┼─► Standard access       │  │
│  │             │              │   (own content only)    │  │
│  └─────────────┘              └─────────────────────────┘  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                  LEVEL HIERARCHY                     │   │
│  │                                                      │   │
│  │  Level3 ──► Access to ALL content (L1 + L2 + L3)    │   │
│  │     ▲                                                │   │
│  │     │                                                │   │
│  │  Level2 ──► Access to L1 + L2 content               │   │
│  │     ▲                                                │   │
│  │     │                                                │   │
│  │  Level1 ──► Access to L1 content only (default)     │   │
│  │                                                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. User Schema (`lib/sahajyog/accounts/user.ex`)

**Changes:**

- Update `@roles` from `~w(admin manager regular)` to `~w(admin user)`
- Update default role from `"regular"` to `"user"`
- Remove `manager?/1` and `regular?/1` helper functions
- Add `user?/1` helper function

```elixir
@roles ~w(admin user)
@levels ~w(Level1 Level2 Level3)

field :role, :string, default: "user"

def admin?(%__MODULE__{role: "admin"}), do: true
def admin?(_), do: false

def user?(%__MODULE__{role: "user"}), do: true
def user?(_), do: false
```

### 2. Content Module (`lib/sahajyog/content.ex`)

**Changes:**

- Fix `@category_access` to follow correct hierarchy (Level3 has most access)

```elixir
@category_access %{
  "Welcome" => [:public, "Level1", "Level2", "Level3"],
  "Getting Started" => [:public, "Level1", "Level2", "Level3"],
  "Advanced Topics" => ["Level2", "Level3"],      # Was ["Level1", "Level2"]
  "Excerpts" => ["Level2", "Level3"]              # Was ["Level1", "Level2"]
}
```

### 3. Events Module (`lib/sahajyog/events.ex`)

**Changes:**

- Update `filter_by_level/2` to use correct hierarchy
- Level1 sees Level1 only
- Level2 sees Level1 + Level2
- Level3 sees Level1 + Level2 + Level3

```elixir
defp filter_by_level(query, level) do
  case level do
    "Level1" -> where(query, [e], e.level == "Level1" or is_nil(e.level))
    "Level2" -> where(query, [e], e.level in ["Level1", "Level2"] or is_nil(e.level))
    "Level3" -> where(query, [e], e.level in ["Level1", "Level2", "Level3"] or is_nil(e.level))
    _ -> where(query, [e], e.level == "Level1" or is_nil(e.level))
  end
end
```

### 4. Resources Module (`lib/sahajyog/resources.ex`)

**Changes:**

- Update level filtering to follow correct hierarchy

### 5. Database Migration

**New migration file:**

- Convert all `role = "regular"` to `role = "user"`
- Convert all `role = "manager"` to `role = "user"`

```elixir
def up do
  execute "UPDATE users SET role = 'user' WHERE role = 'regular'"
  execute "UPDATE users SET role = 'user' WHERE role = 'manager'"
end

def down do
  execute "UPDATE users SET role = 'regular' WHERE role = 'user'"
end
```

## Data Models

### User Model (Updated)

| Field | Type   | Default  | Description                                                 |
| ----- | ------ | -------- | ----------------------------------------------------------- |
| role  | string | "user"   | User's administrative role: "admin" or "user"               |
| level | string | "Level1" | User's content access tier: "Level1", "Level2", or "Level3" |

### Level Access Matrix

| User Level | Can Access                       |
| ---------- | -------------------------------- |
| Level1     | Level1 content only              |
| Level2     | Level1 + Level2 content          |
| Level3     | Level1 + Level2 + Level3 content |

### Role Permissions Matrix

| Permission              | admin | user |
| ----------------------- | ----- | ---- |
| Edit own events         | ✓     | ✓    |
| Edit any event          | ✓     | ✗    |
| Edit own topics         | ✓     | ✓    |
| Edit any topic          | ✓     | ✗    |
| Access admin panel      | ✓     | ✗    |
| View content (by level) | ✓     | ✓    |

## Correctness Properties

_A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees._

### Property 1: Default role assignment

_For any_ newly created user without an explicit role, the assigned role SHALL be "user"
**Validates: Requirements 1.1**

### Property 2: Role validation

_For any_ role value, the system SHALL accept it if and only if it is "admin" or "user"
**Validates: Requirements 1.2**

### Property 3: Level hierarchy content access

_For any_ user with level L and any content item with level C, the user can access the content if and only if C is less than or equal to L in the hierarchy (Level1 < Level2 < Level3)
**Validates: Requirements 3.1, 3.2, 3.3**

### Property 4: Event level filtering

_For any_ user with level L, the list of visible events SHALL include only events with level less than or equal to L
**Validates: Requirements 3.4**

### Property 5: Resource level filtering

_For any_ user with level L, the list of visible resources SHALL include only resources with level less than or equal to L
**Validates: Requirements 3.5**

### Property 6: Video category access

_For any_ user with level L, the accessible video categories SHALL follow the hierarchical access rules where higher levels include all lower-level categories
**Validates: Requirements 3.6, 5.1, 5.2, 5.3**

### Property 7: Admin event edit access

_For any_ admin user and any event, the `can_edit_event?/2` function SHALL return true
**Validates: Requirements 4.1**

### Property 8: Admin topic edit access

_For any_ admin user and any topic, the `can_edit_topic?/2` function SHALL return true
**Validates: Requirements 4.2**

### Property 9: Non-admin event edit restriction

_For any_ non-admin user and any event they do not own and are not a team member of, the `can_edit_event?/2` function SHALL return false
**Validates: Requirements 4.3**

### Property 10: Non-admin topic edit restriction

_For any_ non-admin user and any topic they do not own and are not a co-author of, the `can_edit_topic?/2` function SHALL return false
**Validates: Requirements 4.4**

## Error Handling

| Scenario                                 | Handling                                          |
| ---------------------------------------- | ------------------------------------------------- |
| Invalid role value in changeset          | Return validation error with message "is invalid" |
| Invalid level value in changeset         | Return validation error with message "is invalid" |
| Migration fails                          | Rollback transaction, log error                   |
| User with unknown role accesses content  | Treat as "user" role (fail-safe)                  |
| User with unknown level accesses content | Treat as "Level1" (most restricted, fail-safe)    |

## Testing Strategy

### Dual Testing Approach

This feature will use both unit tests and property-based tests:

1. **Unit Tests**: Verify specific examples, edge cases, and migration behavior
2. **Property-Based Tests**: Verify universal properties hold across all valid inputs

### Property-Based Testing Framework

We will use **StreamData** (Elixir's built-in property-based testing library) for property tests.

Configuration: Each property test will run a minimum of 100 iterations.

### Test Categories

#### Unit Tests

- Migration converts "regular" to "user"
- Migration converts "manager" to "user"
- Default role is "user" for new users
- `admin?/1` returns true for admin users
- `user?/1` returns true for user users
- Role validation rejects invalid values

#### Property-Based Tests

- **Property 1**: Default role assignment
- **Property 2**: Role validation
- **Property 3**: Level hierarchy content access
- **Property 4**: Event level filtering
- **Property 5**: Resource level filtering
- **Property 6**: Video category access
- **Property 7**: Admin event edit access
- **Property 8**: Admin topic edit access
- **Property 9**: Non-admin event edit restriction
- **Property 10**: Non-admin topic edit restriction

### Test File Structure

```
test/
├── sahajyog/
│   ├── accounts/
│   │   └── user_role_test.exs          # Unit + Property tests for role/level
│   ├── events_level_test.exs           # Property tests for event filtering
│   ├── resources_level_test.exs        # Property tests for resource filtering
│   └── content_level_test.exs          # Property tests for video category access
└── sahajyog_web/
    └── live/
        └── event_show_live_test.exs    # Integration tests for edit access
```

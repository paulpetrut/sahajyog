# Requirements Document

## Introduction

This feature cleans up the event level field by removing the redundant `nil` handling. Currently, the Event schema has `default: "Level1"` but queries still check for `is_nil(e.level)` to handle legacy data. This creates confusion since `nil` and `"Level1"` have identical behavior. This cleanup will migrate any existing `nil` values and simplify the query logic.

## Glossary

- **Level**: A content access tier that determines which users can view an event ("Level1", "Level2", "Level3")
- **Event**: A scheduled activity that users can attend, with visibility controlled by level
- **Level Hierarchy**: The ordering Level1 < Level2 < Level3 where higher levels see more content

## Requirements

### Requirement 1

**User Story:** As a developer, I want all events to have an explicit level value, so that the data model is consistent and queries are simpler.

#### Acceptance Criteria

1. WHEN the database migration runs THEN the System SHALL convert all existing events with `level = NULL` to `level = 'Level1'`
2. WHEN querying events by level THEN the System SHALL NOT check for `is_nil(e.level)` conditions
3. WHEN the Event schema defines the level field THEN the System SHALL enforce a default value of "Level1"

### Requirement 2

**User Story:** As a developer, I want the level filtering logic to be simplified, so that the code is easier to understand and maintain.

#### Acceptance Criteria

1. WHEN filtering events for Level1 users THEN the System SHALL return events where `level == "Level1"`
2. WHEN filtering events for Level2 users THEN the System SHALL return events where `level in ["Level1", "Level2"]`
3. WHEN filtering events for Level3 users THEN the System SHALL return events where `level in ["Level1", "Level2", "Level3"]`
4. WHEN the `filter_by_level/2` function is called THEN the System SHALL NOT include `or is_nil(e.level)` in any query condition

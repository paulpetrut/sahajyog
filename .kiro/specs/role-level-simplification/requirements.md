# Requirements Document

## Introduction

This feature simplifies the user authorization model by consolidating roles and fixing the level access hierarchy. Currently, the application has three roles (`admin`, `manager`, `regular`) but only `admin` is actually used. The levels (`Level1`, `Level2`, `Level3`) have an inverted access hierarchy where Level3 users have less access than Level1 users. This refactoring will create a cleaner, more intuitive authorization model.

## Glossary

- **Role**: A user attribute that determines administrative privileges (ability to manage all content)
- **Level**: A user attribute that determines content access tiers (which events, resources, and topics a user can view)
- **Admin**: A role with full administrative privileges to edit any content and access admin panels
- **User**: A standard role with no special administrative privileges
- **Level1**: Entry-level access tier for new users (most restricted content access)
- **Level2**: Intermediate access tier with access to more content than Level1
- **Level3**: Highest access tier with access to all content

## Requirements

### Requirement 1

**User Story:** As a system administrator, I want to simplify user roles to only "admin" and "user", so that the authorization model is cleaner and easier to maintain.

#### Acceptance Criteria

1. WHEN a new user registers THEN the System SHALL assign the role "user" as the default value
2. WHEN the System validates a user role THEN the System SHALL only accept "admin" or "user" as valid values
3. WHEN the database migration runs THEN the System SHALL convert all existing "regular" role values to "user"
4. WHEN the database migration runs THEN the System SHALL convert all existing "manager" role values to "user"

### Requirement 2

**User Story:** As a developer, I want to remove all references to the unused "manager" and "regular" roles, so that the codebase is cleaner and less confusing.

#### Acceptance Criteria

1. WHEN the User module defines available roles THEN the System SHALL only include "admin" and "user" in the roles list
2. WHEN the codebase is searched for "manager" role checks THEN the System SHALL return zero matches
3. WHEN the codebase is searched for "regular" role checks THEN the System SHALL return zero matches
4. WHEN helper functions check user roles THEN the System SHALL provide `admin?/1` and `user?/1` functions only

### Requirement 3

**User Story:** As a user, I want the level hierarchy to grant increasing access (Level1 < Level2 < Level3), so that upgrading my level gives me access to more content.

#### Acceptance Criteria

1. WHEN a Level1 user views content THEN the System SHALL display only Level1 content
2. WHEN a Level2 user views content THEN the System SHALL display Level1 and Level2 content
3. WHEN a Level3 user views content THEN the System SHALL display Level1, Level2, and Level3 content
4. WHEN filtering events by user level THEN the System SHALL apply the correct hierarchical access rules
5. WHEN filtering resources by user level THEN the System SHALL apply the correct hierarchical access rules
6. WHEN filtering video categories by user level THEN the System SHALL apply the correct hierarchical access rules

### Requirement 4

**User Story:** As an admin, I want to retain the ability to edit any event or topic regardless of ownership, so that I can moderate content across the platform.

#### Acceptance Criteria

1. WHEN an admin user views an event THEN the System SHALL display the edit button regardless of event ownership
2. WHEN an admin user views a topic THEN the System SHALL display the edit button regardless of topic ownership
3. WHEN a non-admin user views an event they do not own THEN the System SHALL hide the edit button unless they are a team member
4. WHEN a non-admin user views a topic they do not own THEN the System SHALL hide the edit button unless they are a co-author

### Requirement 5

**User Story:** As a developer, I want the content access configuration to follow the correct level hierarchy, so that higher levels have access to all lower-level content.

#### Acceptance Criteria

1. WHEN configuring video category access THEN the System SHALL grant Level3 users access to all categories
2. WHEN configuring video category access THEN the System SHALL grant Level2 users access to Level1 and Level2 categories
3. WHEN configuring video category access THEN the System SHALL grant Level1 users access to Level1 categories only
4. WHEN configuring resource access THEN the System SHALL follow the same hierarchical pattern as video categories

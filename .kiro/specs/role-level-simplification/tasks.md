# Implementation Plan

- [x] 1. Update User schema and role definitions

  - [x] 1.1 Update the `@roles` constant from `~w(admin manager regular)` to `~w(admin user)`
    - Modify `lib/sahajyog/accounts/user.ex`
    - Change default role from `"regular"` to `"user"`
    - _Requirements: 1.1, 2.1_
  - [x] 1.2 Update helper functions in User module
    - Remove `manager?/1` function
    - Remove `regular?/1` function
    - Add `user?/1` function
    - _Requirements: 2.4_
  - [x] 1.3 Write property test for role validation
    - **Property 2: Role validation**
    - **Validates: Requirements 1.2**
  - [x] 1.4 Write property test for default role assignment
    - **Property 1: Default role assignment**
    - **Validates: Requirements 1.1**

- [x] 2. Create database migration for role conversion

  - [x] 2.1 Create migration file to convert existing roles
    - Convert all `role = "regular"` to `role = "user"`
    - Convert all `role = "manager"` to `role = "user"`
    - _Requirements: 1.3, 1.4_
  - [x] 2.2 Write unit tests for migration behavior
    - Test that "regular" users are converted to "user"
    - Test that "manager" users are converted to "user"
    - Test that "admin" users remain unchanged
    - _Requirements: 1.3, 1.4_

- [x] 3. Checkpoint - Ensure all tests pass

  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Fix level hierarchy in Content module

  - [x] 4.1 Update `@category_access` map in Content module
    - Change "Advanced Topics" access from `["Level1", "Level2"]` to `["Level2", "Level3"]`
    - Change "Excerpts" access from `["Level1", "Level2"]` to `["Level2", "Level3"]`
    - _Requirements: 5.1, 5.2, 5.3_
  - [x] 4.2 Write property test for video category access
    - **Property 6: Video category access**
    - **Validates: Requirements 3.6, 5.1, 5.2, 5.3**

- [x] 5. Fix level hierarchy in Events module

  - [x] 5.1 Update `filter_by_level/2` function in Events module
    - Level1 users see Level1 content only
    - Level2 users see Level1 + Level2 content
    - Level3 users see Level1 + Level2 + Level3 content
    - _Requirements: 3.1, 3.2, 3.3, 3.4_
  - [x] 5.2 Update `list_events_for_user/2` dynamic queries
    - Fix the public_access dynamic query for each level
    - _Requirements: 3.4_
  - [x] 5.3 Write property test for event level filtering
    - **Property 4: Event level filtering**
    - **Validates: Requirements 3.4**

- [x] 6. Fix level hierarchy in Resources module

  - [x] 6.1 Update resource filtering logic in Resources module
    - Ensure Level1 users see Level1 resources only
    - Ensure Level2 users see Level1 + Level2 resources
    - Ensure Level3 users see all resources
    - _Requirements: 3.5, 5.4_
  - [x] 6.2 Write property test for resource level filtering
    - **Property 5: Resource level filtering**
    - **Validates: Requirements 3.5**

- [x] 7. Checkpoint - Ensure all tests pass

  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Verify admin edit access remains intact

  - [x] 8.1 Review `can_edit_event?/2` function in Events module
    - Verify admin check uses `user.role == "admin"`
    - No changes needed if already correct
    - _Requirements: 4.1_
  - [x] 8.2 Review `can_edit_topic?/2` function in Topics module
    - Verify admin check uses `user.role == "admin"`
    - No changes needed if already correct
    - _Requirements: 4.2_
  - [x] 8.3 Write property tests for admin edit access
    - **Property 7: Admin event edit access**
    - **Property 8: Admin topic edit access**
    - **Validates: Requirements 4.1, 4.2**
  - [x] 8.4 Write property tests for non-admin edit restrictions
    - **Property 9: Non-admin event edit restriction**
    - **Property 10: Non-admin topic edit restriction**
    - **Validates: Requirements 4.3, 4.4**

- [x] 9. Update any remaining role references in codebase

  - [x] 9.1 Search and update any hardcoded "regular" or "manager" references
    - Check LiveViews, controllers, and templates
    - Update any role-related UI elements
    - _Requirements: 2.2, 2.3_

- [x] 10. Run precommit and verify all changes

  - [x] 10.1 Run `mix precommit` to check for issues
    - Fix any compilation errors
    - Fix any test failures
    - Fix any formatting issues
    - _Requirements: All_

- [x] 11. Final Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

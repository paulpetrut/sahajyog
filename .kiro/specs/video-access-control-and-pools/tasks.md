# Implementation Plan

- [x] 1. Database migrations and schema updates

  - [x] 1.1 Create migration to add pool fields to videos table
    - Add `pool_position` integer field (nullable)
    - Add `in_pool` boolean field with default false
    - Create index on `[:category, :in_pool]`
    - Create partial index on `[:pool_position]` where `in_pool = true`
    - _Requirements: 2.1_
  - [x] 1.2 Create migration for weekly_video_assignments table
    - Create table with `year`, `week_number`, `video_id` fields
    - Add foreign key to videos with `on_delete: :delete_all`
    - Create unique index on `[:video_id, :year, :week_number]`
    - Create index on `[:year, :week_number]`
    - _Requirements: 4.1, 7.3_
  - [x] 1.3 Update Video schema with new fields and associations
    - Add `pool_position` and `in_pool` fields to schema
    - Add `has_many :weekly_assignments` association
    - Update changeset to handle new fields
    - _Requirements: 2.1_
  - [x] 1.4 Create WeeklyVideoAssignment schema
    - Define schema with `year`, `week_number` fields
    - Add `belongs_to :video` association
    - Implement changeset with validations (week 1-53)
    - _Requirements: 4.1_

- [x] 2. Implement access control in Content context

  - [x] 2.1 Add category access configuration and helper functions
    - Define `@category_access` map with level permissions
    - Implement `accessible_categories/1` function
    - Implement `can_access_category?/2` function
    - _Requirements: 3.1, 3.2, 3.3, 3.4_
  - [x] 2.2 Write property test for access control
    - **Property 1: Access Control by Level**
    - **Validates: Requirements 3.1, 3.2, 3.3, 3.4**
  - [x] 2.3 Implement list_videos_for_user function
    - Accept user (or nil for unauthenticated)
    - Filter videos by accessible categories
    - Return ordered list of videos
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 3. Implement Welcome pool management

  - [x] 3.1 Implement list_welcome_pool_videos function
    - Query videos where `category = "Welcome"` and `in_pool = true`
    - Order by `pool_position`
    - _Requirements: 2.4_
  - [x] 3.2 Implement add_to_welcome_pool function
    - Validate video exists and is Welcome category
    - Check pool size < 31
    - Assign next available position
    - Set `in_pool = true`
    - _Requirements: 2.1, 2.2_
  - [x] 3.3 Implement remove_from_welcome_pool function
    - Set `in_pool = false` and `pool_position = nil`
    - Renumber remaining videos sequentially
    - _Requirements: 2.5_
  - [x] 3.4 Write property test for pool removal renumbering
    - **Property 6: Pool Removal Renumbering**
    - **Validates: Requirements 2.5**
  - [x] 3.5 Implement reorder_welcome_pool function
    - Accept list of video IDs in new order
    - Update `pool_position` for each video (1 to N)
    - Use transaction for atomicity
    - _Requirements: 2.3_
  - [x] 3.6 Write property test for pool reorder consistency
    - **Property 5: Pool Reorder Consistency**
    - **Validates: Requirements 2.3, 6.3**
  - [x] 3.7 Implement shuffle_welcome_pool function
    - Get all pool videos
    - Randomize order using Enum.shuffle
    - Call reorder_welcome_pool with shuffled IDs
    - _Requirements: 2.6_
  - [x] 3.8 Write property test for pool shuffle validity
    - **Property 7: Pool Shuffle Validity**
    - **Validates: Requirements 2.6**
  - [x] 3.9 Write property test for pool position validity
    - **Property 4: Pool Position Validity**
    - **Validates: Requirements 2.1**

- [x] 4. Implement daily video rotation

  - [x] 4.1 Implement get_daily_video function
    - Calculate day counter from reference date
    - Get pool size
    - Calculate position: `rem(day_counter - 1, pool_size) + 1`
    - Return video at that position
    - _Requirements: 5.1, 5.2, 5.3, 6.2_
  - [x] 4.2 Write property test for daily rotation cycle
    - **Property 2: Daily Rotation Cycle**
    - **Validates: Requirements 5.1, 5.2, 5.3, 6.2**
  - [x] 4.3 Write property test for daily video determinism
    - **Property 3: Daily Video Determinism**
    - **Validates: Requirements 1.1, 1.2, 5.5**

- [x] 5. Checkpoint - Ensure all tests pass

  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Implement weekly video assignments

  - [x] 6.1 Implement assign_videos_to_week function
    - Accept video_ids, year, week_number
    - Validate week_number (1-53)
    - Create WeeklyVideoAssignment records
    - Use upsert to handle re-assignments
    - _Requirements: 4.1, 7.3_
  - [x] 6.2 Write property test for weekly assignment storage
    - **Property 8: Weekly Assignment Storage**
    - **Validates: Requirements 4.1, 7.3**
  - [x] 6.3 Implement remove_video_from_week function
    - Delete assignment for specific video/year/week
    - Preserve other assignments for that week
    - _Requirements: 7.4_
  - [x] 6.4 Write property test for weekly assignment partial removal
    - **Property 10: Weekly Assignment Partial Removal**
    - **Validates: Requirements 7.4**
  - [x] 6.5 Implement get_videos_for_current_week function
    - Accept category parameter
    - Calculate current year and ISO week
    - Query videos with matching assignments
    - _Requirements: 4.2, 4.3, 5.4_
  - [x] 6.6 Write property test for weekly video retrieval
    - **Property 9: Weekly Video Retrieval**
    - **Validates: Requirements 4.2, 4.3, 5.4**
  - [x] 6.7 Implement list_weekly_assignments function
    - Accept year, week_number, category (optional)
    - Return assignments with preloaded videos
    - _Requirements: 4.5, 7.1_

- [x] 7. Update Welcome LiveView

  - [x] 7.1 Update WelcomeLive to use get_daily_video
    - Replace `list_videos_by_category("Welcome")` with `get_daily_video()`
    - Handle nil case (empty pool)
    - _Requirements: 1.1, 1.2, 1.3_

- [x] 8. Update Admin Videos LiveView for pool management

  - [x] 8.1 Add Welcome pool management section to admin UI
    - Display pool videos in order
    - Show current day indicator
    - Add "Add to Pool" / "Remove from Pool" buttons
    - _Requirements: 2.4, 6.1_
  - [x] 8.2 Implement drag-and-drop reordering with JS hook
    - Create Sortable.js hook for drag-and-drop
    - Send reorder event to LiveView
    - Update pool positions on drop
    - _Requirements: 2.3_
  - [x] 8.3 Add shuffle button functionality
    - Add shuffle button to pool UI
    - Call shuffle_welcome_pool on click
    - Refresh pool display
    - _Requirements: 2.6_

- [x] 9. Create Admin Weekly Schedule LiveView

  - [x] 9.1 Create AdminWeeklyScheduleLive module
    - Display calendar/week view
    - Show assigned videos per week
    - Support category filter (Advanced Topics, Excerpts)
    - _Requirements: 4.5, 7.1_
  - [x] 9.2 Implement week selection and video assignment UI
    - Modal or panel for selecting videos
    - Multi-select from available videos in category
    - Save/cancel buttons
    - _Requirements: 7.2, 7.3_
  - [x] 9.3 Implement video removal from week
    - Remove button per video in week view
    - Confirm dialog
    - Update assignments
    - _Requirements: 7.4_
  - [x] 9.4 Add route for weekly schedule admin page
    - Add to admin routes in router
    - Add navigation link in admin nav
    - _Requirements: 7.1_

- [x] 10. Update video display pages with access control

  - [x] 10.1 Update videos listing to respect access levels
    - Use list_videos_for_user instead of list_videos
    - Pass current user from socket assigns
    - _Requirements: 3.1, 3.2, 3.3, 3.4_
  - [x] 10.2 Update Advanced Topics and Excerpts sections
    - Show weekly assigned videos for current week
    - Display empty state when no assignments
    - _Requirements: 4.2, 4.3, 4.4_

- [x] 11. Final Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

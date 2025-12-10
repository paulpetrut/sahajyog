# Implementation Plan

- [x] 1. Database schema and migration

  - [x] 1.1 Create migration to add new fields to event_proposals table
    - Add `meeting_platform_link` (string, nullable)
    - Add `presentation_video_type` (string, nullable)
    - Add `presentation_video_url` (string, nullable)
    - _Requirements: 4.1, 4.2_
  - [x] 1.2 Create migration to add new fields to events table
    - Add `meeting_platform_link` (string, nullable)
    - Add `presentation_video_type` (string, nullable)
    - Add `presentation_video_url` (string, nullable)
    - _Requirements: 4.1, 4.2_

- [x] 2. Schema and validation updates

  - [x] 2.1 Create URL validation helper module
    - Create `Sahajyog.Events.Validators` module
    - Implement `valid_url?/1` for HTTP/HTTPS validation
    - Implement `valid_youtube_url?/1` for YouTube URL validation
    - Implement `extract_youtube_id/1` for extracting video IDs
    - _Requirements: 1.2, 1.3, 2.3_
  - [x] 2.2 Write property test for URL validation
    - **Property 1: Meeting URL Validation**
    - **Validates: Requirements 1.2, 1.3**
  - [x] 2.3 Write property test for YouTube URL validation
    - **Property 2: YouTube URL Validation**
    - **Validates: Requirements 2.3**
  - [x] 2.4 Update EventProposal schema
    - Add new fields to schema definition
    - Update changeset to cast new fields
    - Add validation for meeting_platform_link when is_online is true
    - Add validation for presentation_video_type and presentation_video_url
    - _Requirements: 1.4, 4.1, 4.2_
  - [x] 2.5 Write property test for data persistence round-trip
    - **Property 5: Data Persistence Round-Trip**
    - **Validates: Requirements 4.1, 4.2**
  - [x] 2.6 Update Event schema
    - Add new fields to schema definition
    - Update changeset to cast new fields
    - _Requirements: 4.1, 4.2_

- [x] 3. Context layer updates

  - [x] 3.1 Update Events context for proposal approval
    - Modify `approve_proposal/2` to transfer meeting_platform_link and video data to event
    - _Requirements: 4.3_
  - [x] 3.2 Write property test for proposal to event data transfer
    - **Property 6: Proposal to Event Data Transfer**
    - **Validates: Requirements 4.3**
  - [x] 3.3 Add R2 video cleanup on event deletion
    - Update event deletion to remove R2-hosted videos
    - _Requirements: 4.4_

- [x] 4. Checkpoint - Ensure all tests pass

  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. EventProposeLive form updates

  - [x] 5.1 Add meeting platform link input field
    - Show field when "This is an Online Event" is checked
    - Add validation feedback for invalid URLs
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_
  - [x] 5.2 Add presentation video section
    - Add video source type selector (None, YouTube, Upload)
    - Show YouTube URL input when "YouTube" is selected
    - Add file upload interface when "Upload" is selected
    - _Requirements: 2.1, 2.2, 2.4_
  - [x] 5.3 Implement video file upload to R2
    - Configure LiveView upload for video files
    - Validate file type (MP4, WebM, MOV) and size (500MB max)
    - Upload to R2 under `Events/{slug}/videos/` path
    - _Requirements: 2.5, 2.6, 2.7_
  - [x] 5.4 Write property test for video file format validation
    - **Property 3: Video File Format Validation**
    - **Validates: Requirements 2.6**
  - [x] 5.5 Write property test for R2 storage path format
    - **Property 4: R2 Storage Path Format**
    - **Validates: Requirements 2.5**

- [x] 6. EventShowLive display updates

  - [x] 6.1 Add "Join Meeting" button for online events
    - Display button when event has meeting_platform_link
    - Open link in new tab with target="\_blank"
    - _Requirements: 3.1, 3.2_
  - [x] 6.2 Add presentation video player section
    - Display YouTube embed when video_type is "youtube"
    - Display HTML5 video player when video_type is "r2"
    - Show error message when video is unavailable
    - _Requirements: 3.3, 3.4, 3.5_

- [x] 7. Admin interface updates

  - [x] 7.1 Update Admin.EventProposalsLive to display new fields
    - Show meeting link in proposal review
    - Show video information in proposal review
    - _Requirements: 4.3_
  - [x] 7.2 Update Admin.EventsLive to support editing new fields
    - Add meeting link editing for online events
    - Add video management (view/delete)
    - _Requirements: 4.1, 4.2_

- [x] 8. Final Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

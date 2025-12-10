# Implementation Plan

- [x] 1. Database schema and migration

  - [x] 1.1 Create migration for event_invitation_materials table
    - Add table with fields: id, event_id, filename, original_filename, file_type, file_size, r2_key, uploaded_at, timestamps
    - Add foreign key constraint to events table with CASCADE delete
    - Add index on event_id for performance
    - _Requirements: 4.1, 4.5_

- [x] 2. Schema and validation implementation

  - [x] 2.1 Create EventInvitationMaterial schema module
    - Define Ecto schema with proper field types
    - Implement changeset with validation for file_type, file_size
    - Add allowed file types: jpg, jpeg, png, pdf
    - Set maximum file size to 10MB
    - _Requirements: 1.2, 1.3_
  - [x] 2.2 Write property test for file validation
    - **Property 1: File Type and Size Validation**
    - **Validates: Requirements 1.2, 1.3**
  - [x] 2.3 Update Events context module
    - Add functions: create_invitation_material/2, list_invitation_materials/1
    - Add functions: delete_invitation_material/1, delete_event_materials/1
    - Integrate with existing R2Storage module
    - _Requirements: 2.4, 4.1_
  - [x] 2.4 Write property test for R2 storage paths
    - **Property 2: R2 Storage Path Uniqueness and Format**
    - **Validates: Requirements 1.4, 4.2**

- [x] 3. File upload and storage implementation

  - [x] 3.1 Create file upload helper functions
    - Implement generate_invitation_key/3 for R2 path generation
    - Add file type detection and validation
    - Create sanitize_filename/1 function
    - _Requirements: 1.4, 4.2_
  - [x] 3.2 Integrate with LiveView upload system
    - Configure upload constraints for invitation materials
    - Handle multiple file uploads simultaneously
    - Implement upload progress tracking
    - _Requirements: 2.1, 2.5_
  - [x] 3.3 Write property test for multiple file management
    - **Property 3: Multiple File Upload Independence**
    - **Validates: Requirements 2.1, 2.3, 2.5**

- [x] 4. Checkpoint - Ensure all tests pass

  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. EventProposeLive form updates

  - [x] 5.1 Add invitation materials upload section
    - Create file upload interface for multiple files
    - Add drag-and-drop functionality
    - Display upload progress for each file
    - _Requirements: 1.1, 1.5_
  - [x] 5.2 Implement file management in proposal form
    - Show uploaded files with preview/info
    - Add individual delete buttons for each file
    - Handle upload errors gracefully
    - _Requirements: 2.2, 2.3_
  - [x] 5.3 Write property test for material cleanup
    - **Property 4: Complete Material Cleanup**
    - **Validates: Requirements 2.4**

- [x] 6. EventEditLive form updates

  - [x] 6.1 Add invitation materials management to edit form
    - Display existing materials with previews
    - Allow uploading additional materials
    - Implement individual file deletion
    - _Requirements: 2.2, 2.3, 2.5_
  - [x] 6.2 Handle file upload in edit context
    - Preserve existing materials during updates
    - Validate new uploads against existing materials
    - Update form state after upload/delete operations
    - _Requirements: 2.5_

- [x] 7. EventShowLive display updates

  - [x] 7.1 Add invitation materials display section
    - Show image previews for JPG/PNG files
    - Provide download links for PDF files
    - Display file sizes and names
    - _Requirements: 3.1, 3.2, 3.3_
  - [x] 7.2 Implement responsive materials layout
    - Create grid layout for multiple materials
    - Add lightbox/modal for full-size image viewing
    - Handle cases with no materials gracefully
    - _Requirements: 3.4, 3.5_

- [x] 8. Admin interface updates

  - [x] 8.1 Update Admin.EventProposalsLive
    - Display invitation materials in proposal review
    - Show material count and types in proposal list
    - Allow admin to view/download materials
    - _Requirements: 4.3_
  - [x] 8.2 Update Admin.EventsLive
    - Add materials management to admin event editing
    - Display storage usage information
    - Provide bulk material operations if needed
    - _Requirements: 4.1, 4.4_

- [x] 9. Event deletion cascade implementation

  - [x] 9.1 Update event deletion logic
    - Ensure materials are deleted from R2 before event deletion
    - Add error handling for failed R2 deletions
    - Log material cleanup operations
    - _Requirements: 4.1_
  - [x] 9.2 Write property test for cascade deletion
    - **Property 5: Event Cascade Deletion**
    - **Validates: Requirements 4.1**
  - [x] 9.3 Write property test for referential integrity
    - **Property 6: Event-Material Referential Integrity**
    - **Validates: Requirements 4.5**

- [x] 10. Translation and localization

  - [x] 10.1 Add translation strings for invitation materials
    - Add strings for upload interface labels
    - Add error messages for file validation
    - Add display labels for material types
    - _Requirements: 1.5, 4.3_
  - [x] 10.2 Update all supported language files
    - German, Spanish, French, Italian, Romanian translations
    - Ensure consistent terminology across languages
    - _Requirements: 1.5, 4.3_

- [x] 11. Final Checkpoint - Ensure all tests pass

  - Ensure all tests pass, ask the user if questions arise.

# Implementation Plan

- [x] 1. Create database schemas and migrations

  - [x] 1.1 Create migration for store_items, store_item_media, and store_item_inquiries tables
    - Define all columns as specified in design document
    - Add indexes for user_id, status, store_item_id, buyer_id
    - Add unique constraint on r2_key
    - _Requirements: 1.1, 1.2, 2.6, 5.8_
  - [x] 1.2 Create StoreItem schema with changeset validations
    - Implement field validations (name max 200, description max 2000, quantity > 0, production_cost >= 0)
    - Implement pricing_type conditional validation (price required for fixed_price)
    - Implement delivery_methods presence validation
    - Add status inclusion validation
    - _Requirements: 1.1, 1.6, 1.7, 3.1, 8.1, 8.2, 8.3, 8.4, 8.5_
  - [x] 1.3 Write property tests for StoreItem changeset validations
    - **Property 4: Fixed price requires price field**
    - **Property 11: Delivery method requirement**
    - **Property 24: Name validation constraints**
    - **Property 25: Description length constraint**
    - **Property 26: Quantity positive integer validation**
    - **Property 27: Production cost non-negative validation**
    - **Validates: Requirements 1.6, 1.7, 3.1, 8.1, 8.2, 8.3, 8.4, 8.5**
  - [x] 1.4 Create StoreItemMedia schema with changeset validations
    - Implement content type validation for photos and videos
    - Implement file size validation (50MB photos, 500MB videos)
    - _Requirements: 2.6, 2.7, 2.8, 8.6_
  - [x] 1.5 Write property tests for StoreItemMedia validations
    - **Property 9: Photo content type validation**
    - **Property 10: Video content type validation**
    - **Property 28: Media file size validation**
    - **Validates: Requirements 2.7, 2.8, 8.6**
  - [x] 1.6 Create StoreItemInquiry schema with changeset validations
    - Implement requested_quantity validation (positive integer)
    - Implement message presence validation
    - _Requirements: 5.6, 5.8_

- [x] 2. Implement Store context module

  - [x] 2.1 Implement item CRUD operations
    - create_item/2 with user association and default pending status
    - get_item!/1 and get_item_with_media!/1
    - update_item/3 with status reset logic for approved items
    - delete_item/1 with cascade to media
    - _Requirements: 1.1, 1.2, 1.5, 4.1, 6.2, 6.4_
  - [x] 2.2 Write property tests for item creation
    - **Property 1: Item creation preserves all required fields**
    - **Property 2: Item-user association integrity**
    - **Property 13: New items default to pending status**
    - **Validates: Requirements 1.1, 1.2, 1.5, 4.1**
  - [x] 2.3 Write property tests for item update and delete
    - **Property 21: Edit resets approved status to pending**
    - **Property 23: Item deletion cascades to media**
    - **Validates: Requirements 6.2, 6.4**
  - [x] 2.4 Implement listing queries
    - list_approved_items/1 with optional filters
    - list_pending_items/0 for admin
    - list_user_items/1 for seller dashboard
    - _Requirements: 4.2, 4.6, 5.1, 6.1_
  - [x] 2.5 Write property tests for listing queries
    - **Property 14: Pending items query accuracy**
    - **Property 17: Public listing shows only approved items**
    - **Property 20: User items query returns all statuses**
    - **Validates: Requirements 4.2, 4.6, 5.1, 6.1**
  - [x] 2.6 Implement admin approval/rejection functions
    - approve_item/3 sets status and reviewer_id
    - reject_item/3 requires review_notes
    - mark_item_sold/1 sets status to sold
    - _Requirements: 4.3, 4.4, 6.3_
  - [x] 2.7 Write property tests for status transitions
    - **Property 15: Approval state transition**
    - **Property 16: Rejection requires review notes**
    - **Property 22: Mark sold state transition**
    - **Validates: Requirements 4.3, 4.4, 6.3**
  - [x] 2.8 Implement media management functions
    - add_media/2 with photo/video count limits
    - delete_media/1 with R2 cleanup
    - count_photos/1 and count_videos/1
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 6.5_
  - [x] 2.9 Write property tests for media limits
    - **Property 5: Photo count limit enforcement**
    - **Property 6: Video count limit enforcement**
    - **Property 8: Media metadata completeness**
    - **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.6**
  - [x] 2.10 Implement inquiry functions
    - create_inquiry/3 with quantity validation
    - list_inquiries_for_item/1
    - list_inquiries_for_seller/1
    - _Requirements: 5.6, 5.7, 5.8_
  - [x] 2.11 Write property tests for inquiries
    - **Property 18: Inquiry quantity validation**
    - **Property 19: Inquiry record completeness**
    - **Validates: Requirements 5.6, 5.7, 5.8**

- [x] 3. Checkpoint - Ensure all tests pass

  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Implement R2 storage integration for store items

  - [x] 4.1 Add store item key generation to R2Storage module
    - generate_store_item_key/3 with pattern "sahajaonline/sahajstore/{item_id}/{media_type}/{uuid}-{filename}"
    - _Requirements: 2.5_
  - [x] 4.2 Write property test for R2 key format
    - **Property 7: R2 key format consistency**
    - **Validates: Requirements 2.5**
  - [x] 4.3 Implement presigned URL generation for store media
    - Generate time-limited URLs for photo/video preview
    - _Requirements: 8.8_

- [x] 5. Implement email notifications

  - [x] 5.1 Create StoreNotifier module
    - deliver_item_approved/2
    - deliver_item_rejected/3
    - deliver_inquiry_to_seller/4
    - _Requirements: 4.5, 5.4_
  - [x] 5.2 Write unit tests for email content
    - Test email contains required fields
    - _Requirements: 4.5, 5.4_

- [x] 6. Implement public store LiveViews

  - [x] 6.1 Create SahajStoreLive for browsing approved items
    - Display grid of approved items with thumbnails
    - Add filtering and search capabilities
    - _Requirements: 5.1_
  - [x] 6.2 Create StoreItemShowLive for item detail view
    - Display item details, photos gallery, video player
    - Show seller info with phone visibility logic
    - Include inquiry form with quantity selector
    - _Requirements: 5.2, 5.3, 5.5, 7.3, 7.4, 7.5, 7.6_
  - [x] 6.3 Write property test for phone visibility
    - **Property 3: Phone visibility controls display**
    - **Validates: Requirements 1.3, 1.4, 5.5**

- [x] 7. Implement item creation LiveView

  - [x] 7.1 Create StoreItemCreateLive for new item form
    - Multi-step form with item details, media upload, delivery options
    - Implement live validation
    - _Requirements: 1.1, 1.3, 1.4, 1.6, 1.7, 3.1, 3.2, 3.3, 3.5, 3.6_
  - [x] 7.2 Implement media upload with preview
    - Photo upload with thumbnail preview and delete button
    - Video upload with player preview
    - Upload progress indicators
    - Enforce 5 photo / 1 video limits in UI
    - _Requirements: 2.1, 2.2, 7.1, 7.2, 7.7, 7.8_
  - [x] 7.3 Implement edit functionality
    - Load existing item data and media
    - Handle status reset on edit
    - _Requirements: 6.2_

- [x] 8. Implement seller dashboard LiveView

  - [x] 8.1 Create MyStoreItemsLive for seller's items
    - Display all items with status badges
    - Add edit, delete, mark sold actions
    - Show inquiries received
    - _Requirements: 6.1, 6.3, 6.4, 6.5_

- [x] 9. Implement admin review LiveView

  - [x] 9.1 Create Admin.StoreItemsLive for admin review
    - Display pending items for review
    - Implement approve/reject actions with notes
    - _Requirements: 4.2, 4.3, 4.4_

- [x] 10. Add routes and navigation

  - [x] 10.1 Add store routes to router
    - Public routes: /store, /store/:id
    - Authenticated routes: /store/new, /store/:id/edit, /store/my-items
    - Admin routes: /admin/store-items
    - _Requirements: All_
  - [x] 10.2 Add navigation links to layouts
    - Add SahajStore link to main navigation
    - Add admin link to admin navigation
    - _Requirements: All_

- [x] 11. Implement JSON serialization

  - [x] 11.1 Add JSON encoding for StoreItem
    - Implement Jason.Encoder for StoreItem
    - Include all public fields
    - _Requirements: 8.7_
  - [x] 11.2 Write property test for JSON round-trip
    - **Property 29: Store item JSON round-trip**
    - **Validates: Requirements 8.7**

- [x] 12. Final Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

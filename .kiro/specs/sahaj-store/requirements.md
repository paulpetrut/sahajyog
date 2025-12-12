# Requirements Document

## Introduction

SahajStore is a community marketplace feature that enables users to list items for sale or donation within the Sahajyog platform. Users can post items with photos and videos, set pricing options (fixed price or donation-based), and manage delivery preferences. An admin approval workflow ensures quality control before items become publicly visible. Media files are stored on Cloudflare R2 under the `sahajaonline/sahajstore` path.

## Glossary

- **Store_Item**: A product or item listed on the SahajStore marketplace
- **Store_Item_Media**: Photos or videos associated with a Store_Item
- **Seller**: A registered user who posts items to the SahajStore
- **Pricing_Type**: Either "fixed_price" (set amount) or "accepts_donation" (flexible contribution)
- **Delivery_Method**: How the item will be delivered: "express_delivery", "in_person", "local_pickup", or "shipping"
- **Item_Status**: The approval state of an item: "pending", "approved", "rejected", or "sold"
- **R2_Storage**: Cloudflare R2 object storage service used for media files

## Requirements

### Requirement 1

**User Story:** As a user, I want to create a store item listing with details, so that I can offer items to the community.

#### Acceptance Criteria

1. WHEN a user submits a new store item THEN the Store_System SHALL create a Store_Item record with name, description, quantity, production_cost, pricing_type, and delivery_method
2. WHEN a user creates a store item THEN the Store_System SHALL associate the item with the Seller's user_id, first_name, last_name, email, and optionally phone_number
3. WHEN a user sets phone visibility to true THEN the Store_System SHALL display the phone_number on the public listing
4. WHEN a user sets phone visibility to false THEN the Store_System SHALL hide the phone_number from the public listing
5. WHEN a store item is created THEN the Store_System SHALL record the date_posted timestamp automatically
6. WHEN a user selects "fixed_price" as pricing_type THEN the Store_System SHALL require a price amount field
7. WHEN a user selects "accepts_donation" as pricing_type THEN the Store_System SHALL allow the price field to be optional

### Requirement 2

**User Story:** As a user, I want to upload photos and videos for my store item, so that buyers can see what I am offering.

#### Acceptance Criteria

1. WHEN a user uploads photos for a store item THEN the Store_System SHALL accept a maximum of 5 photo files
2. WHEN a user uploads a video for a store item THEN the Store_System SHALL accept a maximum of 1 video file
3. WHEN a user attempts to upload more than 5 photos THEN the Store_System SHALL reject the upload and display an error message
4. WHEN a user attempts to upload more than 1 video THEN the Store_System SHALL reject the upload and display an error message
5. WHEN media files are uploaded THEN the Store_System SHALL store them in Cloudflare R2 under the path "sahajaonline/sahajstore/{item_id}/"
6. WHEN media files are uploaded THEN the Store_System SHALL store metadata (file_name, content_type, r2_key, media_type) in the database
7. WHEN a photo is uploaded THEN the Store_System SHALL validate the file is an image type (JPEG, PNG, WebP, GIF)
8. WHEN a video is uploaded THEN the Store_System SHALL validate the file is a video type (MP4, WebM, MOV)

### Requirement 3

**User Story:** As a user, I want to specify delivery options for my item, so that buyers know how they can receive the item.

#### Acceptance Criteria

1. WHEN a user creates a store item THEN the Store_System SHALL require at least one delivery_method selection
2. WHEN a user selects "express_delivery" THEN the Store_System SHALL allow the Seller to specify shipping cost
3. WHEN a user selects "in_person" THEN the Store_System SHALL allow the Seller to specify a meeting location or city
4. WHEN a user selects "local_pickup" THEN the Store_System SHALL display the Seller's city from their profile
5. WHEN a user selects "shipping" THEN the Store_System SHALL allow the Seller to specify shipping regions and cost
6. WHEN multiple delivery methods are selected THEN the Store_System SHALL store all selected options for the item

### Requirement 4

**User Story:** As an admin, I want to review and approve or reject store item submissions, so that I can maintain quality and appropriateness of listings.

#### Acceptance Criteria

1. WHEN a store item is submitted THEN the Store_System SHALL set the initial status to "pending"
2. WHEN an admin views pending items THEN the Store_System SHALL display all Store_Items with status "pending"
3. WHEN an admin approves an item THEN the Store_System SHALL update the status to "approved" and record the reviewer_id
4. WHEN an admin rejects an item THEN the Store_System SHALL update the status to "rejected" and require review_notes
5. WHEN an item status changes THEN the Store_System SHALL notify the Seller via email
6. WHILE an item has status "pending" or "rejected" THEN the Store_System SHALL hide the item from public listings

### Requirement 5

**User Story:** As a buyer, I want to browse approved store items and contact sellers, so that I can purchase or inquire about items.

#### Acceptance Criteria

1. WHEN a user visits the SahajStore page THEN the Store_System SHALL display only items with status "approved"
2. WHEN viewing an item listing THEN the Store_System SHALL display name, description, photos, video, quantity, price, delivery_methods, and Seller contact information
3. WHEN a user clicks "Contact Seller" THEN the Store_System SHALL display an inquiry form with quantity selector and message field
4. WHEN a user submits an inquiry THEN the Store_System SHALL send an email to the Seller containing buyer's name, email, requested quantity, and message content
5. WHEN viewing an item THEN the Store_System SHALL display the Seller's first_name, last_name, and phone_number only if phone_visible is true
6. WHEN a user selects quantity in the inquiry form THEN the Store_System SHALL validate that requested quantity does not exceed available quantity
7. WHEN a user attempts to request more items than available THEN the Store_System SHALL display an error and prevent submission
8. WHEN an inquiry is submitted THEN the Store_System SHALL record the inquiry with buyer_id, item_id, requested_quantity, message, and timestamp

### Requirement 6

**User Story:** As a seller, I want to manage my store listings, so that I can update, mark as sold, or remove items.

#### Acceptance Criteria

1. WHEN a seller views their listings THEN the Store_System SHALL display all their Store_Items regardless of status
2. WHEN a seller edits an approved item THEN the Store_System SHALL reset the status to "pending" for re-review
3. WHEN a seller marks an item as sold THEN the Store_System SHALL update the status to "sold" and hide from active listings
4. WHEN a seller deletes an item THEN the Store_System SHALL remove the Store_Item record and associated media from R2 storage
5. WHEN a seller deletes media from an item THEN the Store_System SHALL remove the specific media file from R2 storage

### Requirement 7

**User Story:** As a user, I want to preview photos and videos when creating or viewing store items, so that I can see the media before publishing and buyers can view item details.

#### Acceptance Criteria

1. WHEN a user uploads a photo during item creation THEN the Store_System SHALL display a thumbnail preview of the uploaded image
2. WHEN a user uploads a video during item creation THEN the Store_System SHALL display a video player preview with playback controls
3. WHEN a user views an item listing THEN the Store_System SHALL display photos in a gallery format with thumbnail navigation
4. WHEN a user clicks on a photo thumbnail THEN the Store_System SHALL display the full-size image in a lightbox or modal
5. WHEN a user views an item with a video THEN the Store_System SHALL display an embedded video player with play/pause controls
6. WHEN multiple photos exist THEN the Store_System SHALL allow navigation between photos using previous/next controls
7. WHEN a user is uploading media THEN the Store_System SHALL display upload progress indicators
8. WHEN a user wants to remove an uploaded photo during creation THEN the Store_System SHALL provide a delete button on each preview thumbnail

### Requirement 8

**User Story:** As a system administrator, I want store item data to be validated and persisted correctly, so that the marketplace maintains data integrity.

#### Acceptance Criteria

1. WHEN a store item is created THEN the Store_System SHALL validate that name is present and has maximum 200 characters
2. WHEN a store item is created THEN the Store_System SHALL validate that description has maximum 2000 characters
3. WHEN a store item is created THEN the Store_System SHALL validate that quantity is a positive integer
4. WHEN a store item is created THEN the Store_System SHALL validate that production_cost is a non-negative decimal
5. WHEN a fixed_price item is created THEN the Store_System SHALL validate that price is a positive decimal
6. WHEN media is uploaded THEN the Store_System SHALL validate file size does not exceed 50MB for photos and 500MB for videos
7. WHEN serializing a Store_Item to JSON for API responses THEN the Store_System SHALL produce valid JSON that can be deserialized back to an equivalent structure
8. WHEN generating presigned URLs for media preview THEN the Store_System SHALL create time-limited URLs that expire after a configurable duration

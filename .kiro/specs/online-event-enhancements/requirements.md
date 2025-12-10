# Requirements Document

## Introduction

This feature enhances the "Propose a New Event" form to support online events with meeting platform links and presentation videos. When users mark an event as online, they can specify a meeting platform link (Microsoft Teams, Google Meet, Zoom, etc.) that allows participants to join the meeting directly. Additionally, event proposers can attach a presentation video either by uploading to R2 storage or by providing a YouTube link.

## Glossary

- **Event Proposal System**: The system that handles event proposal creation, validation, and storage
- **Online Meeting Link**: A URL to an external meeting platform (Microsoft Teams, Google Meet, Zoom, etc.) that participants can use to join the online event
- **Presentation Video**: A video that provides information about the event, stored either on R2 cloud storage or linked from YouTube
- **R2 Storage**: Cloudflare R2 object storage service used for storing media files
- **Meeting Platform**: External video conferencing services such as Microsoft Teams, Google Meet, Zoom, Webex, etc.

## Requirements

### Requirement 1

**User Story:** As an event proposer, I want to add an online meeting platform link when creating an online event, so that participants can easily join the meeting using their preferred platform.

#### Acceptance Criteria

1. WHEN a user checks the "This is an Online Event" checkbox THEN the Event Proposal System SHALL display a meeting platform link input field
2. WHEN a user enters a meeting platform URL THEN the Event Proposal System SHALL validate that the URL is a valid HTTP or HTTPS URL
3. WHEN a user enters a meeting platform URL THEN the Event Proposal System SHALL accept URLs from common platforms including Microsoft Teams, Google Meet, Zoom, Webex, and other valid meeting URLs
4. WHEN a user submits an online event proposal without a meeting platform link THEN the Event Proposal System SHALL require the meeting link field to be filled
5. WHEN a user unchecks the "This is an Online Event" checkbox THEN the Event Proposal System SHALL hide the meeting platform link field and clear its value

### Requirement 2

**User Story:** As an event proposer, I want to add a presentation video to my event proposal, so that potential participants can learn more about the event before attending.

#### Acceptance Criteria

1. WHEN a user is creating an event proposal THEN the Event Proposal System SHALL display options to add a presentation video
2. WHEN a user selects YouTube as the video source THEN the Event Proposal System SHALL display an input field for the YouTube video URL
3. WHEN a user enters a YouTube URL THEN the Event Proposal System SHALL validate that the URL matches valid YouTube video URL patterns
4. WHEN a user selects R2 upload as the video source THEN the Event Proposal System SHALL display a file upload interface for video files
5. WHEN a user uploads a video file THEN the Event Proposal System SHALL store the file in R2 under the events/videos subfolder
6. WHEN a user uploads a video file THEN the Event Proposal System SHALL validate that the file is a supported video format (MP4, WebM, MOV)
7. WHEN a user uploads a video file THEN the Event Proposal System SHALL enforce a maximum file size limit of 500MB

### Requirement 3

**User Story:** As an event viewer, I want to see the meeting link and presentation video on the event details page, so that I can join the meeting and watch the presentation.

#### Acceptance Criteria

1. WHEN viewing an online event with a meeting platform link THEN the Event Proposal System SHALL display a clickable "Join Meeting" button
2. WHEN a user clicks the "Join Meeting" button THEN the Event Proposal System SHALL open the meeting link in a new browser tab triggering the external meeting application
3. WHEN viewing an event with a YouTube presentation video THEN the Event Proposal System SHALL display an embedded YouTube video player
4. WHEN viewing an event with an R2-hosted presentation video THEN the Event Proposal System SHALL display a native HTML5 video player
5. WHEN the presentation video source is unavailable THEN the Event Proposal System SHALL display an appropriate error message

### Requirement 4

**User Story:** As a system administrator, I want the meeting links and video data to be properly stored and validated, so that the system maintains data integrity.

#### Acceptance Criteria

1. WHEN storing a meeting platform link THEN the Event Proposal System SHALL persist the URL in the database with the event proposal record
2. WHEN storing a presentation video reference THEN the Event Proposal System SHALL persist the video source type (youtube or r2) and the corresponding URL or path
3. WHEN an event proposal is approved and converted to an event THEN the Event Proposal System SHALL transfer the meeting link and video data to the event record
4. WHEN deleting an event with an R2-hosted video THEN the Event Proposal System SHALL remove the video file from R2 storage

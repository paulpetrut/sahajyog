# Requirements Document

## Introduction

This feature enhances the video management system to add level-based access control (similar to resources) and introduces video pools for scheduled content rotation. The system will restrict "Advanced Topics" and "Excerpts" categories to Level1 and Level2 users, keep "Welcome" videos accessible to everyone, and implement daily/weekly video rotation from configurable pools.

## Glossary

- **Video**: A content item with a URL (YouTube/Vimeo), title, category, and metadata stored in the videos table
- **Video Pool**: A collection of videos designated for scheduled rotation (daily or weekly)
- **Pool Type**: The rotation schedule type - either "daily" (31 videos, one per day) or "weekly" (videos rotated weekly)
- **Access Level**: User permission tier (Level1, Level2, Level3) that determines which video categories a user can view
- **Welcome Category**: Video category accessible to all users including unauthenticated visitors
- **Getting Started Category**: Video category accessible to all authenticated users (Level1, Level2, Level3), displayed as a sequential learning path
- **Advanced Topics Category**: Video category accessible only to Level1 and Level2 users
- **Excerpts Category**: Video category accessible only to Level1 and Level2 users
- **Daily Video**: The single video from the Welcome pool displayed on the welcome page, rotated daily
- **Weekly Assignment**: A set of videos from Advanced Topics or Excerpts pools assigned to display during a specific week (year + week number)
- **Week Number**: ISO week number (1-52/53) used to determine which videos to display

## Requirements

### Requirement 1

**User Story:** As a user, I want to see the Welcome video on the homepage regardless of my authentication status, so that I can experience Sahaja Yoga content immediately.

#### Acceptance Criteria

1. WHEN an unauthenticated user visits the welcome page THEN the Video System SHALL display the daily video from the Welcome pool
2. WHEN an authenticated user visits the welcome page THEN the Video System SHALL display the same daily video from the Welcome pool
3. WHEN the date changes to a new day THEN the Video System SHALL select a different video from the Welcome pool using deterministic rotation

### Requirement 2

**User Story:** As an administrator, I want to manage a pool of up to 31 Welcome videos with a specific playback order, so that users see fresh content each day in my chosen sequence.

#### Acceptance Criteria

1. WHEN an administrator adds a video to the Welcome pool THEN the Video System SHALL store the video with a sequence position (1 through 31 maximum)
2. WHEN the Welcome pool reaches 31 videos THEN the Video System SHALL prevent adding more videos until one is removed
3. WHEN an administrator reorders videos in the Welcome pool THEN the Video System SHALL update the sequence positions to reflect the new order
4. WHEN an administrator views the Welcome pool THEN the Video System SHALL display all pool videos in their sequence order with drag-and-drop reordering capability
5. WHEN an administrator removes a video from the Welcome pool THEN the Video System SHALL remove the video and renumber remaining positions sequentially
6. WHEN an administrator clicks the shuffle button THEN the Video System SHALL randomly reorder all videos in the Welcome pool and update their sequence positions

### Requirement 3

**User Story:** As a Level1 or Level2 user, I want to access Advanced Topics and Excerpts videos, so that I can deepen my meditation practice.

#### Acceptance Criteria

1. WHEN a Level1 user requests videos THEN the Video System SHALL return videos from Welcome, Getting Started, Advanced Topics, and Excerpts categories
2. WHEN a Level2 user requests videos THEN the Video System SHALL return videos from Welcome, Getting Started, Advanced Topics, and Excerpts categories
3. WHEN a Level3 user requests videos THEN the Video System SHALL return videos from Welcome and Getting Started categories only
4. WHEN an unauthenticated user requests videos THEN the Video System SHALL return videos from the Welcome category only

### Requirement 4

**User Story:** As an administrator, I want to assign multiple videos from Advanced Topics and Excerpts pools to specific weeks, so that users see my curated selection each week.

#### Acceptance Criteria

1. WHEN an administrator assigns videos to a week THEN the Video System SHALL store the week assignment (year and week number) for each selected video
2. WHEN a user views the Advanced Topics section THEN the Video System SHALL display all videos assigned to the current week from the Advanced Topics pool
3. WHEN a user views the Excerpts section THEN the Video System SHALL display all videos assigned to the current week from the Excerpts pool
4. WHEN no videos are assigned to the current week THEN the Video System SHALL display an empty state message
5. WHEN an administrator views the weekly schedule THEN the Video System SHALL display a calendar view showing which videos are assigned to each week

### Requirement 5

**User Story:** As a system administrator, I want the video selection to be deterministic based on date, so that all users see the same video on the same day/week.

#### Acceptance Criteria

1. WHEN calculating the daily video THEN the Video System SHALL use a day counter (starting from a reference date) modulo pool size to select from the Welcome pool sequence
2. WHEN the day changes at midnight THEN the Video System SHALL advance to the next video in the sequence
3. WHEN the sequence reaches the last video THEN the Video System SHALL cycle back to video position 1 on the next day
4. WHEN calculating the weekly videos THEN the Video System SHALL use the current year and ISO week number to find assigned videos
5. WHEN multiple users request the daily video simultaneously THEN the Video System SHALL return the same video to all users

### Requirement 6

**User Story:** As an administrator, I want to see which Welcome video will play on any given day, so that I can verify the rotation schedule.

#### Acceptance Criteria

1. WHEN an administrator views the Welcome pool THEN the Video System SHALL display the current day number and which video is playing today
2. WHEN the pool has N videos THEN the Video System SHALL cycle through them in order (Day 1 = video 1, Day 2 = video 2, ..., Day N+1 = video 1)
3. WHEN an administrator changes the sequence order THEN the Video System SHALL immediately reflect the change in the current day's video selection

### Requirement 7

**User Story:** As an administrator, I want to manage the weekly video schedule for Advanced Topics and Excerpts, so that I can plan content weeks or months in advance.

#### Acceptance Criteria

1. WHEN an administrator opens the weekly schedule THEN the Video System SHALL display a calendar view with weeks and their assigned videos
2. WHEN an administrator selects a week THEN the Video System SHALL show available videos from the category pool and allow multiple selections
3. WHEN an administrator saves the week assignment THEN the Video System SHALL store the year, week number, and selected video IDs
4. WHEN an administrator removes a video from a week THEN the Video System SHALL update the assignment while preserving other videos in that week

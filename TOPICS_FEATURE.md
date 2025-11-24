# Topics Feature

A comprehensive blog-like system for creating and managing in-depth articles on Sahaja Yoga topics.

## Features

### For Authenticated Users (Login Required)

- **Browse Topics**: View all published topics at `/topics`
- **Read Topics**: Click on any topic to read the full content with references
- **View References**: Each topic can include books, talks, videos, articles, and websites as references
- **Propose Topics**: Submit topic proposals for admin review at `/topics/propose`
- **Edit Topics**: Authors and co-authors can edit their topics
- **Add References**: Attach relevant resources (books, talks, videos, etc.) to topics

### For Admins

- **Review Proposals**: Approve or reject topic proposals at `/admin/topic-proposals`
- **Create Topics**: When approving a proposal, create the topic with initial content
- **Manage All Topics**: Edit any topic regardless of authorship
- **Invite Co-Authors**: Add other users as co-authors to collaborate on topics

## Database Schema

### Topics

- `title`: Topic title (generates unique slug)
- `slug`: URL-friendly identifier
- `content`: Main article content (text)
- `status`: draft | published | archived
- `language`: en | es | fr | de | it | pt
- `published_at`: Publication timestamp
- `views_count`: Number of views
- `user_id`: Author reference

### Topic Proposals

- `title`: Proposed topic title
- `description`: Brief description of what the topic should cover
- `status`: pending | approved | rejected
- `proposed_by_id`: User who proposed the topic
- `reviewed_by_id`: Admin who reviewed
- `topic_id`: Created topic (if approved)
- `review_notes`: Admin feedback

### Topic Co-Authors

- `topic_id`: Topic reference
- `user_id`: Co-author user
- `status`: pending | accepted | rejected
- `invited_by_id`: User who sent invitation

### Topic References

- `topic_id`: Topic reference
- `reference_type`: book | talk | video | article | website
- `title`: Reference title
- `url`: Link to resource (optional)
- `description`: Brief description
- `position`: Display order

## Routes

### Authenticated Routes (Login Required)

- `GET /topics` - List all published topics
- `GET /topics/:slug` - View single topic
- `GET /topics/propose` - Propose new topic
- `GET /topics/:slug/edit` - Edit topic (author/co-author/admin only)

### Admin Routes

- `GET /admin/topic-proposals` - Review and manage proposals

## Workflow

1. **User proposes a topic** → Status: pending
2. **Admin reviews proposal** → Can approve or reject
3. **If approved** → Topic is created with initial content
4. **Author writes content** → Can add references, format text
5. **Author publishes** → Status changes to published
6. **Topic appears publicly** → Authenticated users can read

## UI/UX Design

The topics feature follows the existing app design with:

- **Dark gradient backgrounds** (gray-900 to gray-800)
- **Blue and purple accent colors** for CTAs
- **Card-based layouts** with hover effects
- **Responsive design** for mobile, tablet, and desktop
- **Smooth transitions** and micro-interactions
- **Icon-based navigation** using Heroicons

## Permissions

- **View published topics**: Authenticated users only
- **Propose topics**: Authenticated users
- **Edit topic**: Author, co-authors, or admin
- **Review proposals**: Admin only
- **Invite co-authors**: Topic author or admin

## Future Enhancements

Potential improvements for the topics feature:

1. **Rich Text Editor**: Integrate a WYSIWYG editor for better formatting
2. **Image Uploads**: Allow embedding images within topic content
3. **Comments**: Enable discussion on topics
4. **Tags/Categories**: Organize topics by themes
5. **Search**: Full-text search across topics
6. **Versioning**: Track content changes over time
7. **Notifications**: Alert co-authors of changes
8. **Social Sharing**: Share topics on social media
9. **Reading Time**: Estimate time to read each topic
10. **Related Topics**: Suggest similar content

## Sample Data

Run `mix run priv/repo/seeds.exs` to create:

- 3 sample published topics
- 2 pending topic proposals

## Testing

All existing tests pass. The feature integrates seamlessly with the authentication system and follows Phoenix LiveView best practices.

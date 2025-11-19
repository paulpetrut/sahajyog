# Resources System - Quick Reference

## Overview

Level-based resource access system using Cloudflare R2 storage.

## Structure

```
R2 Bucket: sahajaonline/
├── Level1/
│   ├── Photos/
│   ├── Books/
│   └── Music/
├── Level2/
│   ├── Photos/
│   ├── Books/
│   └── Music/
└── Level3/
    ├── Photos/
    ├── Books/
    └── Music/
```

## User Access

- Each user has a `level` field (Level1, Level2, or Level3)
- Users can only view and download resources from their assigned level
- Admins can upload resources to any level

## Routes

### Public (Requires Login)

- `/resources` - Browse resources for your level
- `/resources?type=Photos` - Filter by type
- `/resources/:id/download` - Download a resource

### Admin (Requires Admin Role)

- `/admin/resources` - Manage all resources
- `/admin/resources/new` - Upload new resource
- `/admin/resources/:id/edit` - Edit resource metadata

## Environment Variables

```bash
R2_ACCOUNT_ID=your_cloudflare_account_id
R2_ACCESS_KEY_ID=your_r2_access_key
R2_SECRET_ACCESS_KEY=your_r2_secret_key
R2_BUCKET_NAME=sahajaonline
```

## Common Tasks

### Change User Level

```elixir
# In IEx console
user = Sahajyog.Repo.get_by(Sahajyog.Accounts.User, email: "user@example.com")
Ecto.Changeset.change(user, level: "Level2") |> Sahajyog.Repo.update()
```

### Sync Existing R2 Files

```bash
# Preview
mix sync_r2_resources --dry-run

# Sync
mix sync_r2_resources
```

### List Resources for a User

```elixir
user = Sahajyog.Repo.get!(Sahajyog.Accounts.User, 1)
Sahajyog.Resources.list_resources_for_user(user)
```

### Upload Programmatically

```elixir
alias Sahajyog.Resources.R2Storage

# Upload file
{:ok, key} = R2Storage.upload("/path/to/file.pdf", "Level1/Books/file.pdf",
  content_type: "application/pdf")

# Create database record
Sahajyog.Resources.create_resource(%{
  title: "My Book",
  file_name: "file.pdf",
  file_size: 1024000,
  content_type: "application/pdf",
  r2_key: key,
  level: "Level1",
  resource_type: "Books"
})
```

### Generate Download URL

```elixir
resource = Sahajyog.Resources.get_resource!(1)
url = Sahajyog.Resources.R2Storage.generate_download_url(resource.r2_key)
# URL valid for 1 hour
```

## Database Schema

### users table

- `level` - string (Level1, Level2, Level3)

### resources table

- `title` - string
- `description` - text (optional)
- `file_name` - string
- `file_size` - bigint (bytes)
- `content_type` - string
- `r2_key` - string (unique, e.g., "Level1/Books/abc-file.pdf")
- `level` - string (Level1, Level2, Level3)
- `resource_type` - string (Photos, Books, Music)
- `language` - string (optional)
- `downloads_count` - integer
- `user_id` - references users (uploader)

## Security

- Download URLs are presigned and expire after 1 hour
- Users cannot access resources from other levels
- Download attempts are logged via `downloads_count`
- Only admins can upload/edit/delete resources

## File Naming

When uploading, files are stored with a UUID prefix to avoid conflicts:

```
Original: mybook.pdf
Stored as: Level1/Books/abc12345-mybook.pdf
```

## Troubleshooting

### "R2_BUCKET_NAME not configured"

Set environment variables and restart server.

### User can't see any resources

Check their level matches available resources:

```elixir
user = Sahajyog.Repo.get!(Sahajyog.Accounts.User, 1)
IO.inspect(user.level)
Sahajyog.Resources.list_resources(%{level: user.level})
```

### Upload fails

- Verify R2 credentials
- Check file size (max 500MB)
- Ensure level and resource_type are valid

## Next Steps

- Add search functionality
- Implement resource preview for images/PDFs
- Add bulk upload
- Create admin dashboard with analytics
- Add resource versioning

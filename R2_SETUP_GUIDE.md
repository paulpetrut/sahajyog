# Cloudflare R2 Setup Guide - Level-Based Access

This guide will help you set up Cloudflare R2 for storing and serving downloadable resources with level-based access control.

## System Overview

Your R2 bucket uses a **Level/Type** structure:

```
sahajaonline/
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

Users can only access resources from their assigned level (Level1, Level2, or Level3).

## Why Cloudflare R2?

- **Zero egress fees** - No bandwidth charges for downloads
- **S3-compatible API** - Works with existing S3 libraries
- **Built-in CDN** - Fast global delivery
- **Affordable** - $0.015/GB/month storage, 10GB free tier

## Setup Steps

### 1. Use Your Existing R2 Bucket

You already have the `sahajaonline` bucket with the Level/Type structure. No need to create a new one!

### 2. Generate API Tokens

1. In the R2 section, navigate to your bucket settings or overview
2. Look for **Account API Tokens** or **User API Tokens** section
3. Click **Create Account API token** (recommended for production) or **Create User API token** (for development)
4. Give it a name (e.g., `sahajyog-app`)
5. Set permissions:
   - **Admin Read & Write** or **Object Read & Write** (for uploading and generating presigned URLs)
6. Optionally restrict to specific buckets (select your `sahajaonline` bucket)
7. Set TTL (Time to Live) or leave as default
8. Click **Create API Token**
9. **Save these credentials immediately** (you won't see them again):
   - **Access Key ID**
   - **Secret Access Key**
   - Note your **Account ID** from the R2 dashboard URL or endpoint

### 3. Find Your Account ID

Your Account ID is needed for the R2 endpoint. You can find it:

1. In your Cloudflare dashboard URL: `https://dash.cloudflare.com/{ACCOUNT_ID}/r2`
2. Or in the R2 bucket settings under "Bucket Details"
3. Or when you create the API token, it shows the endpoint URL like: `https://{ACCOUNT_ID}.r2.cloudflarestorage.com`

### 4. Configure Environment Variables

Add these to your environment (`.env` file for development, or hosting platform for production):

```bash
# Your Cloudflare Account ID (from dashboard URL or R2 settings)
R2_ACCOUNT_ID=your_account_id_here

# From the API token you created (Access Key ID and Secret Access Key)
R2_ACCESS_KEY_ID=your_access_key_id_here
R2_SECRET_ACCESS_KEY=your_secret_access_key_here

# Your bucket name (use your existing bucket)
R2_BUCKET_NAME=sahajaonline

# Optional: Custom domain for public URLs (set up later)
# R2_PUBLIC_URL=https://resources.yourdomain.com
```

**Important**: Copy the Access Key ID and Secret Access Key immediately when creating the token - you won't be able to see them again!

### 4. Install Dependencies

```bash
mix deps.get
```

This will install:

- `ex_aws` - AWS SDK for Elixir
- `ex_aws_s3` - S3 operations
- `sweet_xml` - XML parsing for S3 responses
- `hackney` - HTTP client

### 5. Run Database Migration

```bash
mix ecto.migrate
```

This creates the `resources` table to track uploaded files.

### 6. Sync Existing Files

Since you already have files in R2, sync them to the database:

```bash
# Preview what will be synced
mix sync_r2_resources --dry-run

# Actually sync the files
mix sync_r2_resources
```

This will scan your R2 bucket and create database records for all files in the Level/Type structure.

### 7. Test the Setup

Start your Phoenix server:

```bash
mix phx.server
```

Visit:

- **Admin upload page**: http://localhost:4000/admin/resources (requires admin login)
- **Public resources page**: http://localhost:4000/resources (requires user login)

Users will only see resources from their assigned level!

## Usage

### Managing User Levels

Users have a `level` field (Level1, Level2, or Level3). You can update this:

1. Via admin interface (when you build user management)
2. Via console:
   ```elixir
   user = Sahajyog.Repo.get_by(Sahajyog.Accounts.User, email: "user@example.com")
   Ecto.Changeset.change(user, level: "Level2") |> Sahajyog.Repo.update()
   ```

### Uploading Resources (Admin)

1. Log in as an admin user
2. Navigate to `/admin/resources`
3. Click **Upload New Resource**
4. Fill in:
   - Title
   - Description (optional)
   - Level (Level1, Level2, or Level3)
   - Type (Photos, Books, or Music)
   - Language (optional
   - File (drag & drop or click to select)
5. Click **Save**

The file will be uploaded to R2 with a unique key like:

```
book/20251119/uuid-filename.pdf
```

### Downloading Resources (Public)

Users can:

1. Browse resources at `/resources`
2. Filter by category
3. Click **Download** to get a secure, time-limited download link

The download URL is a presigned R2 URL valid for 1 hour.

## Optional: Custom Domain

For branded URLs like `https://resources.yourdomain.com/file.pdf`:

1. In Cloudflare R2, go to your bucket settings
2. Click **Connect Domain**
3. Enter your subdomain (e.g., `resources.yourdomain.com`)
4. Cloudflare will automatically configure DNS
5. Update `R2_PUBLIC_URL` environment variable

## Security Notes

- Presigned URLs expire after 1 hour by default
- Only authenticated admins can upload files
- Download counter tracks usage
- Files are stored with UUID prefixes to prevent guessing

## Cost Estimation

For a typical small to medium site:

**Storage**: 50GB × $0.015/GB = $0.75/month
**Operations**: Minimal (Class A: $4.50/million, Class B: $0.36/million)
**Egress**: $0 (R2's main advantage!)

**Total**: ~$1-2/month for most use cases

## Troubleshooting

### "R2_BUCKET_NAME not configured"

- Ensure environment variables are set
- Restart your Phoenix server after adding variables

### Upload fails

- Check API token permissions (needs Object Read & Write)
- Verify Account ID is correct
- Check file size (max 500MB by default)

### Download link doesn't work

- Presigned URLs expire after 1 hour
- Check that the file exists in R2
- Verify bucket permissions

## Production Deployment

For Render.com or similar:

1. Add environment variables in your hosting dashboard
2. Ensure `config/runtime.exs` loads them (already configured)
3. Deploy your app
4. Test upload and download functionality

## API Reference

### R2Storage Module

```elixir
# Upload a file
{:ok, key} = Sahajyog.Resources.R2Storage.upload(file_path, key, content_type: "image/jpeg")

# Generate download URL
url = Sahajyog.Resources.R2Storage.generate_download_url(key)

# Delete a file
:ok = Sahajyog.Resources.R2Storage.delete(key)

# List objects
{:ok, objects} = Sahajyog.Resources.R2Storage.list_objects("book/")
```

### Resources Context

```elixir
# List all resources
resources = Sahajyog.Resources.list_resources()

# Filter by category
books = Sahajyog.Resources.list_resources(%{category: "book"})

# Get a resource
resource = Sahajyog.Resources.get_resource!(id)

# Increment downloads
Sahajyog.Resources.increment_downloads(resource)
```

## Next Steps

- Add search functionality
- Implement resource categories in navigation
- Add file preview for images/PDFs
- Set up automated backups
- Add admin analytics dashboard

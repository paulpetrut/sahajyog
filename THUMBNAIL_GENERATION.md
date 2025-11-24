# Automatic Thumbnail Generation

The application automatically generates thumbnails for uploaded resources on `/admin/resources/new` using the **Thumbnex** library.

## Supported File Types

- **Images** (JPG, PNG, GIF, WebP, etc.) - Resized to 300x300
- **PDFs** - First page extracted and converted to thumbnail
- **Videos** (MP4, MOV, AVI, etc.) - Frame extracted at 1 second mark
- **Audio** (MP3, WAV, FLAC, etc.) - Embedded album art extracted (if available)

## Dependencies

The application uses **Thumbnex** (`{:thumbnex, "~> 0.4.1"}`), which requires:

### ImageMagick (for images and PDFs)

**Ubuntu/Debian (Production on Render.com):**

```bash
sudo apt-get update
sudo apt-get install imagemagick
```

**macOS (Local Development):**

```bash
brew install imagemagick
```

### FFmpeg (for videos and audio)

**Ubuntu/Debian (Production on Render.com):**

```bash
sudo apt-get update
sudo apt-get install ffmpeg
```

**macOS (Local Development):**

```bash
brew install ffmpeg
```

## How It Works

1. When a file is uploaded on `/admin/resources/new`, the system checks if a manual thumbnail was provided
2. If no manual thumbnail exists, Thumbnex automatically generates one based on the file type
3. The generated thumbnail is uploaded to R2 storage alongside the main file
4. If thumbnail generation fails (missing tools or unsupported format), the resource is still created without a thumbnail

## Manual Thumbnails

You can still upload custom thumbnails manually. If provided, the manual thumbnail takes precedence over auto-generation.

## Checking Dependencies

To verify that Thumbnex is available, you can run in IEx:

```elixir
Sahajyog.Resources.ThumbnailGenerator.check_dependencies()
# Returns: %{thumbnex: true}
```

To test thumbnail generation:

```elixir
# Test with an image file
Sahajyog.Resources.ThumbnailGenerator.generate("/path/to/image.jpg", "image/jpeg")
# Returns: {:ok, "/tmp/thumb_xxxxx.jpg"} or {:error, reason}
```

## Troubleshooting

If thumbnails are not being generated:

1. Check that ImageMagick and FFmpeg are installed
2. Check the logs for thumbnail generation errors
3. Verify file permissions in the temp directory
4. For PDFs, ensure Ghostscript is installed (usually comes with ImageMagick)

## Production Deployment on Render.com

### Option 1: Using Dockerfile

Add to your `Dockerfile`:

```dockerfile
RUN apt-get update && apt-get install -y \
    imagemagick \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*
```

### Option 2: Using Native Environment

If you're using Render's native Elixir environment (not Docker), add a build command in your `render.yaml`:

```yaml
services:
  - type: web
    name: sahajyog
    env: elixir
    buildCommand: |
      apt-get update
      apt-get install -y imagemagick ffmpeg
      mix deps.get --only prod
      mix compile
      mix assets.deploy
    # ... rest of config
```

Or set it in the Render dashboard under "Build Command".

## Installation Steps

1. Add Thumbnex to `mix.exs` (already done):

   ```elixir
   {:thumbnex, "~> 0.4.1"}
   ```

2. Install dependencies:

   ```bash
   mix deps.get
   ```

3. Install system tools (ImageMagick and FFmpeg) as shown above

4. Deploy to production

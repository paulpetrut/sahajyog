# Database Backup Guide

This guide covers multiple methods for backing up your PostgreSQL database on Render.com.

## Method 1: Render Dashboard (Easiest)

### Manual Backup via Render Dashboard

1. Go to https://dashboard.render.com
2. Navigate to your PostgreSQL database (`sahajyog-db`)
3. Click on the "Backups" tab
4. Click "Create Backup" button
5. Download the backup file when ready

**Note:** Free tier databases don't include automatic backups. Paid plans ($7+/month) include:

- Daily automatic backups
- 7-day retention for Starter plan
- 30-day retention for Standard plan

## Method 2: pg_dump via Render Shell (Recommended)

### Create a Backup

1. Go to your database in Render dashboard
2. Click "Shell" tab (or use Render CLI)
3. Run the backup command:

```bash
pg_dump $DATABASE_URL > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Download the Backup

Since you can't directly download from the shell, you'll need to:

1. Create a backup and upload it somewhere (S3, Dropbox, etc.)
2. Or use Method 3 below to backup from your local machine

## Method 3: Local Backup via pg_dump (Most Flexible)

### Prerequisites

Install PostgreSQL client tools on your machine:

**macOS:**

```bash
brew install postgresql
```

**Linux:**

```bash
sudo apt-get install postgresql-client
```

### Get Database Connection String

1. Go to Render dashboard → Your database
2. Copy the "External Database URL" (not Internal)
3. It looks like: `postgres://user:password@host:port/database`

### Create Backup

```bash
# Basic backup
pg_dump "YOUR_DATABASE_URL" > sahajyog_backup_$(date +%Y%m%d).sql

# Compressed backup (recommended for large databases)
pg_dump "YOUR_DATABASE_URL" | gzip > sahajyog_backup_$(date +%Y%m%d).sql.gz

# Custom format (allows selective restore)
pg_dump -Fc "YOUR_DATABASE_URL" > sahajyog_backup_$(date +%Y%m%d).dump
```

### Backup Script

Create a file `backup_database.sh`:

```bash
#!/bin/bash

# Load DATABASE_URL from .env or set it here
# DATABASE_URL="postgres://user:password@host:port/database"

if [ -z "$DATABASE_URL" ]; then
    echo "Error: DATABASE_URL not set"
    echo "Usage: DATABASE_URL='your_url' ./backup_database.sh"
    exit 1
fi

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/sahajyog_backup_$TIMESTAMP.sql.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "Creating backup..."
pg_dump "$DATABASE_URL" | gzip > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✓ Backup created successfully: $BACKUP_FILE"
    echo "  Size: $(du -h "$BACKUP_FILE" | cut -f1)"
else
    echo "✗ Backup failed"
    exit 1
fi

# Optional: Keep only last 7 backups
echo "Cleaning old backups (keeping last 7)..."
ls -t "$BACKUP_DIR"/sahajyog_backup_*.sql.gz | tail -n +8 | xargs -r rm
echo "✓ Done"
```

Make it executable:

```bash
chmod +x backup_database.sh
```

Run it:

```bash
DATABASE_URL="your_database_url" ./backup_database.sh
```

## Method 4: Using Mix Task (Application-Level Backup)

You already have `mix export_data` which exports data to Elixir format. Let's enhance it for SQL backup:

Create `lib/mix/tasks/backup_database.ex`:

```elixir
defmodule Mix.Tasks.BackupDatabase do
  @moduledoc """
  Creates a database backup using pg_dump.

  Usage:
      mix backup_database
      mix backup_database --output backups/custom_name.sql.gz
  """
  use Mix.Task

  @shortdoc "Creates a database backup"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args,
      strict: [output: :string],
      aliases: [o: :output]
    )

    # Get database URL from config
    Mix.Task.run("app.config")
    config = Application.get_env(:sahajyog, Sahajyog.Repo)
    database_url = config[:url] || System.get_env("DATABASE_URL")

    unless database_url do
      Mix.raise("DATABASE_URL not configured")
    end

    # Generate filename
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601() |> String.replace(~r/[:\.]/, "-")
    default_output = "backups/sahajyog_backup_#{timestamp}.sql.gz"
    output_file = opts[:output] || default_output

    # Create backups directory
    output_dir = Path.dirname(output_file)
    File.mkdir_p!(output_dir)

    Mix.shell().info("Creating backup: #{output_file}")

    # Run pg_dump
    case System.cmd("pg_dump", [database_url],
      stderr_to_stdout: true,
      into: File.stream!(output_file <> ".tmp")
    ) do
      {_, 0} ->
        # Compress the backup
        case System.cmd("gzip", ["-f", output_file <> ".tmp"]) do
          {_, 0} ->
            File.rename!(output_file <> ".tmp.gz", output_file)
            {:ok, stat} = File.stat(output_file)
            size_mb = Float.round(stat.size / 1_024 / 1_024, 2)
            Mix.shell().info("✓ Backup created successfully: #{output_file} (#{size_mb} MB)")
          {output, _} ->
            Mix.shell().error("Compression failed: #{output}")
        end

      {output, _} ->
        Mix.shell().error("Backup failed: #{output}")
        File.rm(output_file <> ".tmp")
    end
  end
end
```

## Restoring from Backup

### Restore to Local Database

```bash
# From plain SQL
psql "YOUR_LOCAL_DATABASE_URL" < backup.sql

# From compressed SQL
gunzip -c backup.sql.gz | psql "YOUR_LOCAL_DATABASE_URL"

# From custom format
pg_restore -d "YOUR_LOCAL_DATABASE_URL" backup.dump
```

### Restore to Render (CAUTION!)

**⚠️ WARNING: This will overwrite your production database!**

```bash
# Drop and recreate database (via Render shell)
dropdb $DATABASE_URL
createdb $DATABASE_URL

# Restore from backup
psql $DATABASE_URL < backup.sql

# Or from compressed
gunzip -c backup.sql.gz | psql $DATABASE_URL
```

## Automated Backup Strategy

### Option 1: Cron Job (Local/Server)

Add to your crontab:

```bash
# Daily backup at 2 AM
0 2 * * * DATABASE_URL="your_url" /path/to/backup_database.sh

# Weekly backup on Sunday at 3 AM
0 3 * * 0 DATABASE_URL="your_url" /path/to/backup_database.sh
```

### Option 2: GitHub Actions

Create `.github/workflows/backup.yml`:

```yaml
name: Database Backup

on:
  schedule:
    - cron: "0 2 * * *" # Daily at 2 AM UTC
  workflow_dispatch: # Manual trigger

jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install PostgreSQL client
        run: sudo apt-get install -y postgresql-client

      - name: Create backup
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
        run: |
          mkdir -p backups
          pg_dump "$DATABASE_URL" | gzip > backups/backup_$(date +%Y%m%d).sql.gz

      - name: Upload to artifact
        uses: actions/upload-artifact@v3
        with:
          name: database-backup
          path: backups/*.sql.gz
          retention-days: 30
```

Add `DATABASE_URL` to your GitHub repository secrets.

### Option 3: Render Cron Job

If you upgrade to a paid plan, you can create a Cron Job service on Render:

1. Create a new Cron Job in Render
2. Set schedule (e.g., `0 2 * * *` for daily at 2 AM)
3. Set command: `pg_dump $DATABASE_URL | gzip > /tmp/backup.sql.gz && curl -F "file=@/tmp/backup.sql.gz" YOUR_STORAGE_URL`

## Best Practices

1. **Test your backups regularly** - Restore to a test database to verify
2. **Store backups in multiple locations** - Don't keep them only on Render
3. **Encrypt sensitive backups** - Use GPG or similar for production data
4. **Keep multiple versions** - Don't overwrite your only backup
5. **Document your restore process** - Make sure you can restore quickly
6. **Monitor backup size** - Growing size might indicate issues
7. **Automate backups** - Don't rely on manual backups

## Storage Options for Backups

- **Local machine** - Good for development, not for production
- **Cloud storage** - AWS S3, Google Cloud Storage, Backblaze B2
- **Git LFS** - For small databases (not recommended for large DBs)
- **Dropbox/Google Drive** - Easy but not ideal for automation
- **Render paid plan** - Automatic backups included

## Quick Reference

```bash
# Create backup
pg_dump "$DATABASE_URL" | gzip > backup.sql.gz

# Restore backup
gunzip -c backup.sql.gz | psql "$DATABASE_URL"

# List database size
psql "$DATABASE_URL" -c "SELECT pg_size_pretty(pg_database_size(current_database()));"

# Backup specific tables only
pg_dump "$DATABASE_URL" -t users -t videos | gzip > partial_backup.sql.gz
```

## Troubleshooting

**"pg_dump: command not found"**

- Install PostgreSQL client tools (see Prerequisites)

**"connection refused"**

- Check if you're using the External Database URL (not Internal)
- Verify your IP is allowed (Render allows all by default)

**Backup is too large**

- Use compression (`gzip`)
- Use custom format (`-Fc`)
- Backup only necessary tables

**Slow backup**

- This is normal for large databases
- Consider backing up during low-traffic hours
- Use `--jobs=4` flag for parallel backup (custom format only)

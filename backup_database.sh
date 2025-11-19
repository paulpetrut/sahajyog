#!/bin/bash

# Database Backup Script for Sahajyog
# Usage: DATABASE_URL='your_url' ./backup_database.sh

if [ -z "$DATABASE_URL" ]; then
    echo "Error: DATABASE_URL not set"
    echo "Usage: DATABASE_URL='your_url' ./backup_database.sh"
    echo ""
    echo "Get your DATABASE_URL from Render dashboard:"
    echo "  1. Go to your database in Render"
    echo "  2. Copy the 'External Database URL'"
    exit 1
fi

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/sahajyog_backup_$TIMESTAMP.sql.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "Creating backup..."
echo "Timestamp: $TIMESTAMP"

pg_dump "$DATABASE_URL" | gzip > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✓ Backup created successfully: $BACKUP_FILE"
    echo "  Size: $(du -h "$BACKUP_FILE" | cut -f1)"
    
    # Optional: Keep only last 7 backups
    echo ""
    echo "Cleaning old backups (keeping last 7)..."
    ls -t "$BACKUP_DIR"/sahajyog_backup_*.sql.gz 2>/dev/null | tail -n +8 | xargs -r rm
    
    echo ""
    echo "Current backups:"
    ls -lh "$BACKUP_DIR"/sahajyog_backup_*.sql.gz 2>/dev/null || echo "  (none)"
    
    echo ""
    echo "✓ Done"
else
    echo "✗ Backup failed"
    exit 1
fi

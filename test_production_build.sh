#!/bin/bash
# Test production build locally before deploying

echo "🔨 Testing production build..."
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

echo "✅ Docker is running"
echo ""

# Build the Docker image
echo "📦 Building Docker image..."
docker build -t sahajyog:test .

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Docker image built successfully!"
    echo ""
    echo "To run the container locally, you'll need to:"
    echo "1. Set up a PostgreSQL database"
    echo "2. Run with environment variables:"
    echo ""
    echo "docker run -p 4000:4000 \\"
    echo "  -e DATABASE_URL='ecto://user:pass@host/db' \\"
    echo "  -e SECRET_KEY_BASE='your-secret-key' \\"
    echo "  -e PHX_HOST='localhost' \\"
    echo "  sahajyog:test"
else
    echo ""
    echo "❌ Build failed. Check the errors above."
    exit 1
fi

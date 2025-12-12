#!/bin/bash

# Development Data Setup Script
# This script sets up comprehensive test data for development environment

echo "🚀 Setting up development dataset..."

# Check if we're in development environment
if [ "$MIX_ENV" = "prod" ]; then
    echo "❌ This script is for development only. Cannot run in production."
    exit 1
fi

# Ensure we're in development mode
export MIX_ENV=dev

echo "📦 Installing dependencies..."
mix deps.get

echo "🗄️  Setting up database..."
mix ecto.setup

echo "🌱 Running development seeds..."
mix run priv/repo/dev_seeds.exs

echo "✅ Development environment setup complete!"
echo ""
echo "🔗 You can now:"
echo "  • Start the server: mix phx.server"
echo "  • Visit: http://localhost:4000"
echo "  • Login with test accounts (see output above)"
echo ""
echo "📊 The database now contains comprehensive test data for:"
echo "  • User accounts and roles"
echo "  • Video content and weekly assignments"
echo "  • Topics and proposals"
echo "  • Events and event management"
echo "  • Resources and downloads"
echo "  • Progress tracking"
echo "  • Access codes"
echo ""
echo "⚠️  Remember: This is development data only!"
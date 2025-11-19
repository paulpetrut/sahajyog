#!/bin/bash
# Load environment variables from .env file
# Usage: source load_env.sh

if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
  echo "✅ Environment variables loaded from .env"
else
  echo "❌ .env file not found"
fi

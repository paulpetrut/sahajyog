#!/bin/bash
# Generate a secret key for production use
# Run this locally and copy the output to Render's SECRET_KEY_BASE environment variable

echo "Generating SECRET_KEY_BASE..."
echo ""
mix phx.gen.secret
echo ""
echo "Copy the above value and set it as SECRET_KEY_BASE in Render's environment variables"

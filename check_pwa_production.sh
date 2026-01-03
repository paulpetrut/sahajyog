#!/bin/bash

# PWA Production Checker
# Usage: ./check_pwa_production.sh https://your-app.onrender.com

if [ -z "$1" ]; then
    echo "Usage: ./check_pwa_production.sh https://your-app.onrender.com"
    exit 1
fi

URL=$1
echo "🔍 Checking PWA setup for: $URL"
echo "=========================================="
echo ""

# Check manifest.json
echo "📄 Checking manifest.json..."
MANIFEST_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL/manifest.json")
if [ "$MANIFEST_STATUS" = "200" ]; then
    echo "✅ manifest.json is accessible (HTTP $MANIFEST_STATUS)"
    echo "Content:"
    curl -s "$URL/manifest.json" | jq '.' 2>/dev/null || curl -s "$URL/manifest.json"
else
    echo "❌ manifest.json returned HTTP $MANIFEST_STATUS"
fi
echo ""

# Check service worker
echo "⚙️  Checking service worker..."
SW_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL/sw.js")
if [ "$SW_STATUS" = "200" ]; then
    echo "✅ sw.js is accessible (HTTP $SW_STATUS)"
    SW_CONTENT_TYPE=$(curl -s -I "$URL/sw.js" | grep -i "content-type" | tr -d '\r')
    echo "Content-Type: $SW_CONTENT_TYPE"
else
    echo "❌ sw.js returned HTTP $SW_STATUS"
fi
echo ""

# Check icons
echo "🖼️  Checking icons..."
ICON_192=$(curl -s -o /dev/null -w "%{http_code}" "$URL/images/logo-192-actual.png")
ICON_512=$(curl -s -o /dev/null -w "%{http_code}" "$URL/images/logo-512.png")

if [ "$ICON_192" = "200" ]; then
    echo "✅ logo-192-actual.png is accessible (HTTP $ICON_192)"
else
    echo "❌ logo-192-actual.png returned HTTP $ICON_192"
fi

if [ "$ICON_512" = "200" ]; then
    echo "✅ logo-512.png is accessible (HTTP $ICON_512)"
else
    echo "❌ logo-512.png returned HTTP $ICON_512"
fi
echo ""

# Check HTTPS
echo "🔒 Checking HTTPS..."
if [[ $URL == https://* ]]; then
    echo "✅ Using HTTPS"
else
    echo "❌ Not using HTTPS (required for PWA)"
fi
echo ""

# Check headers
echo "📋 Checking important headers..."
curl -s -I "$URL" | grep -i "content-security-policy\|x-frame-options\|strict-transport"
echo ""

echo "=========================================="
echo "✨ Check complete!"
echo ""
echo "Next steps:"
echo "1. If manifest.json or sw.js return 404, check static file serving"
echo "2. If icons return 404, verify files exist in priv/static/images/"
echo "3. Test in browser DevTools → Application tab"

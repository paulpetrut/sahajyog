#!/bin/bash

echo "🔍 PWA Setup Verification"
echo "=========================="
echo ""

# Check if icon files exist
echo "📱 Checking icon files..."
if [ -f "priv/static/images/logo-192-actual.png" ]; then
    echo "✅ logo-192-actual.png exists"
else
    echo "❌ logo-192-actual.png missing"
fi

if [ -f "priv/static/images/logo-512.png" ]; then
    echo "✅ logo-512.png exists"
else
    echo "❌ logo-512.png missing"
fi

echo ""

# Check manifest.json
echo "📄 Checking manifest.json..."
if [ -f "priv/static/manifest.json" ]; then
    echo "✅ manifest.json exists"
    echo "Content:"
    cat priv/static/manifest.json | jq '.' 2>/dev/null || cat priv/static/manifest.json
else
    echo "❌ manifest.json missing"
fi

echo ""

# Check service worker
echo "⚙️  Checking service worker..."
if [ -f "priv/static/sw.js" ]; then
    echo "✅ sw.js exists"
    if grep -q "addEventListener('fetch'" priv/static/sw.js; then
        echo "✅ Fetch handler present"
    else
        echo "❌ Fetch handler missing"
    fi
else
    echo "❌ sw.js missing"
fi

echo ""

# Check service worker registration in app.js
echo "🔧 Checking service worker registration..."
if grep -q "serviceWorker" assets/js/app.js; then
    echo "✅ Service worker registration found in app.js"
else
    echo "❌ Service worker registration missing in app.js"
fi

echo ""

# Check static paths configuration
echo "📦 Checking static paths..."
if grep -q "manifest.json" lib/sahajyog_web.ex; then
    echo "✅ manifest.json in static paths"
else
    echo "❌ manifest.json not in static paths"
fi

if grep -q "sw.js" lib/sahajyog_web.ex; then
    echo "✅ sw.js in static paths"
else
    echo "❌ sw.js not in static paths"
fi

echo ""

# Check HTML meta tags
echo "🏷️  Checking HTML meta tags..."
if grep -q 'rel="manifest"' lib/sahajyog_web/components/layouts/root.html.heex; then
    echo "✅ Manifest link present"
else
    echo "❌ Manifest link missing"
fi

if grep -q 'apple-mobile-web-app-capable' lib/sahajyog_web/components/layouts/root.html.heex; then
    echo "✅ Apple mobile web app meta tag present"
else
    echo "❌ Apple mobile web app meta tag missing"
fi

if grep -q 'theme-color' lib/sahajyog_web/components/layouts/root.html.heex; then
    echo "✅ Theme color meta tag present"
else
    echo "❌ Theme color meta tag missing"
fi

echo ""
echo "=========================="
echo "✨ Verification complete!"
echo ""
echo "Next steps:"
echo "1. Run 'mix phx.digest' to prepare static assets"
echo "2. Deploy to Render.com"
echo "3. Test on mobile device with Chrome/Safari"
echo "4. Check DevTools → Application → Manifest"
echo ""

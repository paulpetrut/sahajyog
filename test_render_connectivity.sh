#!/bin/bash

echo "🔍 Testing API connectivity from Render.com deployment..."
echo "============================================================"

# Test basic network connectivity
echo ""
echo "📡 Testing basic network connectivity..."
ping -c 3 learnsahajayoga.org || echo "❌ Ping failed"

# Test DNS resolution
echo ""
echo "🔍 Testing DNS resolution..."
nslookup learnsahajayoga.org || echo "❌ DNS lookup failed"

# Test HTTPS connectivity
echo ""
echo "🌐 Testing HTTPS connectivity..."
curl -I --connect-timeout 10 --max-time 30 https://learnsahajayoga.org/ || echo "❌ HTTPS connection failed"

# Test API endpoints
echo ""
echo "🚀 Testing API endpoints..."

endpoints=(
    "https://learnsahajayoga.org/api/talks?lang=en"
    "https://learnsahajayoga.org/api/search?q=test&lang=en"
    "https://learnsahajayoga.org/api/meta/countries"
    "https://learnsahajayoga.org/api/meta/years"
)

for endpoint in "${endpoints[@]}"; do
    echo ""
    echo "Testing: $endpoint"
    
    # Test with curl
    response=$(curl -s -w "HTTPSTATUS:%{http_code};TIME:%{time_total}" \
                   --connect-timeout 10 \
                   --max-time 30 \
                   "$endpoint")
    
    http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    time_total=$(echo "$response" | grep -o "TIME:[0-9.]*" | cut -d: -f2)
    body=$(echo "$response" | sed -E 's/HTTPSTATUS:[0-9]*;TIME:[0-9.]*$//')
    
    if [ "$http_code" = "200" ]; then
        echo "✅ Success (HTTP $http_code) - ${time_total}s"
        echo "   Response preview: $(echo "$body" | head -c 100)..."
    else
        echo "❌ Failed (HTTP $http_code) - ${time_total}s"
        echo "   Error: $body"
    fi
done

echo ""
echo "============================================================"
echo "✅ Connectivity test completed"

# Run the Elixir connectivity test if available
if command -v mix &> /dev/null; then
    echo ""
    echo "🧪 Running Elixir connectivity test..."
    mix test_api_connectivity || echo "❌ Elixir test failed"
fi
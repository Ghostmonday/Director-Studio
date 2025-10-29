#!/bin/bash

echo "🧪 Testing Pollo API Direct Call..."
echo "=================================================="

# Get the API key from Supabase first
SUPABASE_URL="https://carkncjucvtbggqrilwj.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhcmtuY2p1Y3Z0YmdncXJpbHdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1NjQ1NjIsImV4cCI6MjA3NjE0MDU2Mn0.Iksm_EIXh4UpBFRt7rXv08SuqfJYyJZbwB9yK0lGyes"

echo "1. Fetching Pollo API key from Supabase..."
POLLO_KEY=$(curl -s \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ANON_KEY" \
  "$SUPABASE_URL/rest/v1/api_keys?service=eq.Pollo&select=key" | \
  grep -o '"key":"[^"]*"' | cut -d'"' -f4)

if [ -z "$POLLO_KEY" ]; then
  echo "❌ Failed to fetch Pollo API key from Supabase"
  exit 1
fi

echo "✅ Got Pollo key: ${POLLO_KEY:0:15}..."
echo ""

echo "2. Testing Pollo API with video generation request..."
echo ""

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST "https://pollo.ai/api/platform/generation/pollo/pollo-v1-6" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $POLLO_KEY" \
  -d '{
    "input": {
      "prompt": "A dragon breathing fire",
      "resolution": "480p",
      "length": 10,
      "mode": "basic"
    }
  }')

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

echo "📡 HTTP Status: $HTTP_STATUS"
echo "📦 Response Body:"
echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ SUCCESS! Pollo API is working correctly."
  TASK_ID=$(echo "$BODY" | grep -o '"taskId":"[^"]*"' | cut -d'"' -f4)
  echo "📋 Task ID: $TASK_ID"
elif [ "$HTTP_STATUS" = "400" ]; then
  echo "❌ HTTP 400 - Bad Request"
  echo ""
  echo "Possible causes:"
  echo "  1. Invalid request format (check JSON structure)"
  echo "  2. Invalid API key format"
  echo "  3. Missing required fields"
  echo "  4. API endpoint changed"
  echo ""
  echo "Check the response body above for specific error message."
elif [ "$HTTP_STATUS" = "401" ]; then
  echo "❌ HTTP 401 - Unauthorized"
  echo ""
  echo "API key is invalid or expired."
  echo "Current key: ${POLLO_KEY:0:20}..."
  echo ""
  echo "Get a new key from: https://pollo.ai/dashboard (or wherever you signed up)"
elif [ "$HTTP_STATUS" = "403" ]; then
  echo "❌ HTTP 403 - Forbidden"
  echo ""
  echo "API key doesn't have permission for this endpoint."
else
  echo "❌ Unexpected HTTP status: $HTTP_STATUS"
fi

echo ""
echo "=================================================="
echo "If you got HTTP 400, paste the response body above to diagnose."
echo ""


#!/bin/bash

# Test Supabase API Key Endpoint
# Run this after applying the SQL migration

echo "🧪 Testing Supabase API Key Endpoint..."
echo "=================================================="

SUPABASE_URL="https://carkncjucvtbggqrilwj.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhcmtuY2p1Y3Z0YmdncXJpbHdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1NjQ1NjIsImV4cCI6MjA3NjE0MDU2Mn0.Iksm_EIXh4UpBFRt7rXv08SuqfJYyJZbwB9yK0lGyes"

echo ""
echo "Testing Pollo key fetch..."
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "Content-Type: application/json" \
  "$SUPABASE_URL/rest/v1/api_keys?service=eq.Pollo&select=key")

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

if [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ HTTP 200 - Success!"
  echo "Response: $BODY"
else
  echo "❌ HTTP $HTTP_STATUS - Failed!"
  echo "Response: $BODY"
  echo ""
  echo "Common issues:"
  echo "  - HTTP 400: Table doesn't exist (run migration)"
  echo "  - HTTP 401: Auth failed (check anon key)"
  echo "  - HTTP 404: Wrong endpoint"
  echo "  - Empty array []: No keys inserted"
fi

echo ""
echo "Testing DeepSeek key fetch..."
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "Content-Type: application/json" \
  "$SUPABASE_URL/rest/v1/api_keys?service=eq.DeepSeek&select=key")

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

if [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ HTTP 200 - Success!"
  echo "Response: $BODY"
else
  echo "❌ HTTP $HTTP_STATUS - Failed!"
  echo "Response: $BODY"
fi

echo ""
echo "=================================================="
echo "If both tests show HTTP 200 with key data, you're good!"
echo "If you see [] (empty array), insert your API keys in Supabase."
echo ""


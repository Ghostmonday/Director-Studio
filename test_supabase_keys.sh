#!/bin/bash
# Test Supabase API key endpoint directly (simulates what the app does)

SUPABASE_URL="https://carkncjucvtbggqrilwj.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhcmtuY2p1Y3Z0YmdncXJpbHdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1NjQ1NjIsImV4cCI6MjA3NjE0MDU2Mn0.Iksm_EIXh4UpBFRt7rXv08SuqfJYyJZbwB9yK0lGyes"

echo "🧪 Testing Supabase API Key Fetching..."
echo ""

for SERVICE in "Pollo" "DeepSeek"; do
    echo "Testing service: $SERVICE"
    echo "expandURL: ${SUPABASE_URL}/rest/v1/api_keys?service=eq.${SERVICE}&select=key"
    echo ""
    
    RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        "${SUPABASE_URL}/rest/v1/api_keys?service=eq.${SERVICE}&select=key")
    
    HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
    BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')
    
    echo "HTTP Status: $HTTP_STATUS"
    echo "Response: $BODY"
    
    if [ "$HTTP_STATUS" = "200" ]; then
        KEY_PREVIEW=$(echo "$BODY" | grep -o '"key":"[^"]*' | cut -d'"' -f4 | head -c 20)
        if [ -n "$KEY_PREVIEW" ]; then
            echo "✅ SUCCESS - Key preview: ${KEY_PREVIEW}..."
        else
            echo "⚠️  Got 200 but no key in response"
        fi
    elif [ "$HTTP_STATUS" = "400" ]; then
        echo "❌ HTTP 400 - Bad Request"
        echo "   Check: Service name, RLS policy, table structure"
    elif [ "$HTTP_STATUS" = "401" ]; then
        echo "❌ HTTP 401 - Unauthorized"
        echo "   Check: Supabase anon key is correct"
    elif [ "$HTTP_STATUS" = "404" ]; then
        echo "❌ HTTP 404 - Not Found"
        echo "   Check: Table exists, service name matches"
    else
        echo "❌ HTTP $HTTP_STATUS - Unexpected error"
    fi
    
    echo ""
    echo "---"
    echo ""
done

echo "✅ Test complete. Check results above."


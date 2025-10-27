#!/bin/bash

echo "🚨🚨🚨 SUPABASE API KEY SERVICE TEST 🚨🚨🚨"
echo ""
echo "Testing if Supabase is serving API keys correctly"
echo ""

SUPABASE_URL="https://xduwbxbulphvuqqfjrec.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhkdXdieGJ1bHBodnVxcWZqcmVjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE0MDcyMzIsImV4cCI6MjA3Njk4MzIzMn0.dtRj2vDMrLlJSeZ-5wvl-krQLn0IG9Wnzuqgm_AzwSw"

echo "=================================================="
echo "TEST 1: Check Supabase Connection"
echo "=================================================="
echo ""

TEST_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X GET "${SUPABASE_URL}/rest/v1/api_keys?select=service,key" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}")

HTTP_STATUS=$(echo "$TEST_RESPONSE" | grep "HTTP_STATUS" | cut -d':' -f2)
RESPONSE_BODY=$(echo "$TEST_RESPONSE" | sed '/HTTP_STATUS/d')

echo "Status Code: $HTTP_STATUS"
echo "Response:"
echo "$RESPONSE_BODY"
echo ""

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Supabase connection successful"
else
    echo "❌ Supabase connection failed"
fi

echo ""
echo "=================================================="
echo "TEST 2: Fetch Pollo API Key from Supabase"
echo "=================================================="
echo ""

POLLO_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X GET "${SUPABASE_URL}/rest/v1/api_keys?service=eq.Pollo&select=key" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}")

HTTP_STATUS=$(echo "$POLLO_RESPONSE" | grep "HTTP_STATUS" | cut -d':' -f2)
RESPONSE_BODY=$(echo "$POLLO_RESPONSE" | sed '/HTTP_STATUS/d')

echo "Status Code: $HTTP_STATUS"
echo "Response:"
echo "$RESPONSE_BODY"

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Pollo key fetched successfully"
    
    # Extract the key
    POLLO_KEY=$(echo "$RESPONSE_BODY" | grep -o '"key":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$POLLO_KEY" ]; then
        echo "Key length: ${#POLLO_KEY} characters"
        echo "Key starts with: ${POLLO_KEY:0:15}..."
    else
        echo "⚠️ Could not extract key from response"
    fi
else
    echo "❌ Failed to fetch Pollo key"
fi

echo ""
echo "=================================================="
echo "TEST 3: Fetch DeepSeek API Key from Supabase"
echo "=================================================="
echo ""

DEEPSEEK_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X GET "${SUPABASE_URL}/rest/v1/api_keys?service=eq.DeepSeek&select=key" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}")

HTTP_STATUS=$(echo "$DEEPSEEK_RESPONSE" | grep "HTTP_STATUS" | cut -d':' -f2)
RESPONSE_BODY=$(echo "$DEEPSEEK_RESPONSE" | sed '/HTTP_STATUS/d')

echo "Status Code: $HTTP_STATUS"
echo "Response:"
echo "$RESPONSE_BODY"

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ DeepSeek key fetched successfully"
    
    # Extract the key
    DEEPSEEK_KEY=$(echo "$RESPONSE_BODY" | grep -o '"key":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$DEEPSEEK_KEY" ]; then
        echo "Key length: ${#DEEPSEEK_KEY} characters"
        echo "Key starts with: ${DEEPSEEK_KEY:0:15}..."
    else
        echo "⚠️ Could not extract key from response"
    fi
else
    echo "❌ Failed to fetch DeepSeek key"
fi

echo ""
echo "=================================================="
echo "🏁 SUPABASE API KEY TEST COMPLETE"
echo "=================================================="



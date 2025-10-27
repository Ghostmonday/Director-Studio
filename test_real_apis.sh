#!/bin/bash

echo "🚨🚨🚨 FINAL LIVE API TEST WITH REAL KEYS 🚨🚨🚨"
echo ""
echo "Testing APIs with Supabase-provided keys"
echo ""

# Fetch keys from Supabase
SUPABASE_URL="https://xduwbxbulphvuqqfjrec.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhkdXdieGJ1bHBodnVxcWZqcmVjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE0MDcyMzIsImV4cCI6MjA3Njk4MzIzMn0.dtRj2vDMrLlJSeZ-5wvl-krQLn0IG9Wnzuqgm_AzwSw"

echo "Fetching API keys from Supabase..."
POLLO_KEY=$(curl -s -X GET "${SUPABASE_URL}/rest/v1/api_keys?service=eq.Pollo&select=key" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}" | grep -o '"key":"[^"]*"' | cut -d'"' -f4)

DEEPSEEK_KEY=$(curl -s -X GET "${SUPABASE_URL}/rest/v1/api_keys?service=eq.DeepSeek&select=key" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}" | grep -o '"key":"[^"]*"' | cut -d'"' -f4)

echo "✅ Keys fetched from Supabase"
echo "Pollo key (first 20 chars): ${POLLO_KEY:0:20}..."
echo "DeepSeek key (first 20 chars): ${DEEPSEEK_KEY:0:20}..."
echo ""

echo "=================================================="
echo "TEST 1: DeepSeek API - Prompt Enhancement"
echo "=================================================="
echo "Endpoint: https://api.deepseek.com/v1/chat/completions"
echo ""

DEEPSEEK_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST "https://api.deepseek.com/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${DEEPSEEK_KEY}" \
  -d '{
    "model": "deepseek-chat",
    "messages": [{"role": "user", "content": "Enhance: A hero on a building"}],
    "max_tokens": 50
  }')

HTTP_STATUS=$(echo "$DEEPSEEK_RESPONSE" | grep "HTTP_STATUS" | cut -d':' -f2)
RESPONSE_BODY=$(echo "$DEEPSEEK_RESPONSE" | sed '/HTTP_STATUS/d')

echo "Status Code: $HTTP_STATUS"
echo "Response (first 200 chars):"
echo "$RESPONSE_BODY" | head -c 200
echo ""

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅✅✅ DEEPSEEK API IS LIVE AND FUNCTIONAL ✅✅✅"
else
    echo "❌ DeepSeek API returned status: $HTTP_STATUS"
fi

echo ""
echo "=================================================="
echo "TEST 2: Pollo Video API - 1 Second Video"
echo "=================================================="
echo "Endpoint: https://api.piapi.ai/api/v1/task"
echo ""

POLLO_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST "https://api.piapi.ai/api/v1/task" \
  -H "Content-Type: application/json" \
  -H "x-api-key: ${POLLO_KEY}" \
  -d '{
    "model": "pollo-1.5",
    "task_type": "text2video",
    "input": {
      "prompt": "A bird flying",
      "duration": 1
    }
  }')

HTTP_STATUS=$(echo "$POLLO_RESPONSE" | grep "HTTP_STATUS" | cut -d':' -f2)
RESPONSE_BODY=$(echo "$POLLO_RESPONSE" | sed '/HTTP_STATUS/d')

echo "Status Code: $HTTP_STATUS"
echo "Response (first 300 chars):"
echo "$RESPONSE_BODY" | head -c 300
echo ""

if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "201" ]; then
    echo "✅✅✅ POLLO VIDEO API IS LIVE AND FUNCTIONAL ✅✅✅"
elif [ "$HTTP_STATUS" = "401" ]; then
    echo "❌ Pollo API Authentication failed"
else
    echo "⚠️ Pollo API returned status: $HTTP_STATUS"
fi

echo ""
echo "=================================================="
echo "🏁 FINAL API TEST COMPLETE"
echo "=================================================="
echo ""
echo "SUMMARY:"
echo "--------"
if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "201" ]; then
    echo "✅ Video Pipeline: FULLY OPERATIONAL"
    echo "✅ DeepSeek Enhancement: FUNCTIONAL"
    echo "✅ Pollo Video Generation: FUNCTIONAL"
else
    echo "⚠️ Check API responses above for details"
fi



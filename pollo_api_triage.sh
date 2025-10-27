#!/bin/bash

echo "🔍🔍🔍 POLLO API INTEGRATION TRIAGE 🔍🔍🔍"
echo ""
echo "Testing ALL possible Pollo API endpoints and payload structures"
echo ""

# Get API key from Supabase
SUPABASE_URL="https://xduwbxbulphvuqqfjrec.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhkdXdieGJ1bHBodnVxcWZqcmVjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE0MDcyMzIsImV4cCI6MjA3Njk4MzIzMn0.dtRj2vDMrLlJSeZ-5wvl-krQLn0IG9Wnzuqgm_AzwSw"

POLLO_KEY=$(curl -s -X GET "${SUPABASE_URL}/rest/v1/api_keys?service=eq.Pollo&select=key" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}" | grep -o '"key":"[^"]*"' | cut -d'"' -f4)

echo "✅ Using Pollo key: ${POLLO_KEY:0:20}..."
echo ""

# Test 1: Current implementation (WRONG based on my analysis)
echo "=================================================="
echo "TEST 1: Current Implementation"
echo "=================================================="
echo "Endpoint: https://api.pollo.ai/v1/video/generate"
echo "Method: POST"
echo "Headers: Authorization: Bearer {key}"
echo "Body: Flat JSON"
echo ""

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST "https://api.pollo.ai/v1/video/generate" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${POLLO_KEY}" \
  -d '{
    "prompt": "A bird flying",
    "duration": 1,
    "resolution": "1920x1080",
    "fps": 30
  }')

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d':' -f2)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

echo "Status: $HTTP_STATUS"
echo "Response: $RESPONSE_BODY"
echo ""

# Test 2: PiAPI endpoint with wrapped input
echo "=================================================="
echo "TEST 2: PiAPI Endpoint (piapi.ai)"
echo "=================================================="
echo "Endpoint: https://api.piapi.ai/api/v1/task"
echo "Headers: x-api-key: {key}"
echo "Body: Wrapped in 'input' object"
echo ""

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
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

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d':' -f2)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

echo "Status: $HTTP_STATUS"
echo "Response: $RESPONSE_BODY"
echo ""

# Test 3: Pollo platform endpoint
echo "=================================================="
echo "TEST 3: Pollo Platform Endpoint"
echo "=================================================="
echo "Endpoint: https://pollo.ai/api/platform/generation/pollo/pollo-v1-6"
echo "Headers: x-api-key: {key}"
echo "Body: Nested input structure"
echo ""

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST "https://pollo.ai/api/platform/generation/pollo/pollo-v1-6" \
  -H "Content-Type: application/json" \
  -H "x-api-key: ${POLLO_KEY}" \
  -d '{
    "input": {
      "prompt": "A bird flying",
      "resolution": "480p",
      "length": 1
    }
  }')

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d':' -f2)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

echo "Status: $HTTP_STATUS"
echo "Response: $RESPONSE_BODY"
echo ""

# Test 4: Pollo platform endpoint (alternative format)
echo "=================================================="
echo "TEST 4: Pollo Platform Endpoint (Alternative)"
echo "=================================================="
echo "Endpoint: https://pollo.ai/api/platform/generation/pollo/pollo-v1-6"
echo "Headers: Authorization: Bearer {key}"
echo "Body: Nested input structure"
echo ""

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST "https://pollo.ai/api/platform/generation/pollo/pollo-v1-6" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${POLLO_KEY}" \
  -d '{
    "input": {
      "prompt": "A bird flying",
      "resolution": "480p",
      "length": 1
    }
  }')

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d':' -f2)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

echo "Status: $HTTP_STATUS"
echo "Response: $RESPONSE_BODY"
echo ""

echo "=================================================="
echo "🏁 TRIAGE COMPLETE"
echo "=================================================="
echo ""
echo "ANALYSIS:"
echo "--------"
echo "Check which test returned HTTP 200 or 201 to identify the correct API structure"
echo ""



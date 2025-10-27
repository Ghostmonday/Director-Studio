#!/bin/bash

echo "🚨🚨🚨 LIVE API CONNECTIVITY TEST 🚨🚨🚨"
echo ""
echo "Testing REAL APIs - Money on the line!"
echo "MINIMIZING COST: Using 1-second video request"
echo ""

# Get API keys from xcconfig files (prefer local, fallback to regular)
LOCAL_SECRETS="DirectorStudio/Configuration/Secrets.local.xcconfig"
SECRETS_FILE="DirectorStudio/Configuration/Secrets.xcconfig"

if [ -f "$LOCAL_SECRETS" ]; then
    echo "📄 Reading API keys from $LOCAL_SECRETS"
    DEEPSEEK_KEY=$(grep "DEEPSEEK_API_KEY" "$LOCAL_SECRETS" | cut -d'=' -f2 | tr -d ' ')
    POLLO_KEY=$(grep "POLLO_API_KEY" "$LOCAL_SECRETS" | cut -d'=' -f2 | tr -d ' ')
elif [ -f "$SECRETS_FILE" ]; then
    echo "📄 Reading API keys from $SECRETS_FILE"
    DEEPSEEK_KEY=$(grep "DEEPSEEK_API_KEY" "$SECRETS_FILE" | cut -d'=' -f2 | tr -d ' ')
    POLLO_KEY=$(grep "POLLO_API_KEY" "$SECRETS_FILE" | cut -d'=' -f2 | tr -d ' ')
else
    echo "⚠️ No secrets file found, using placeholder keys"
    DEEPSEEK_KEY="YOUR_KEY_HERE"
    POLLO_KEY="YOUR_KEY_HERE"
fi

echo ""
echo "DEEPSEEK_KEY (first 10 chars): ${DEEPSEEK_KEY:0:10}..."
echo "POLLO_KEY (first 10 chars): ${POLLO_KEY:0:10}..."
echo ""

echo "=================================================="
echo "TEST 1: DeepSeek API Connectivity"
echo "=================================================="
echo "Endpoint: https://api.deepseek.com/v1/chat/completions"
echo "Testing prompt enhancement (MINIMAL COST)..."
echo ""

DEEPSEEK_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST "https://api.deepseek.com/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $DEEPSEEK_KEY" \
  -d '{
    "model": "deepseek-chat",
    "messages": [{"role": "user", "content": "Test"}],
    "max_tokens": 10
  }')

HTTP_STATUS=$(echo "$DEEPSEEK_RESPONSE" | grep "HTTP_STATUS" | cut -d':' -f2)
RESPONSE_BODY=$(echo "$DEEPSEEK_RESPONSE" | sed '/HTTP_STATUS/d')

echo "Status Code: $HTTP_STATUS"
echo "Response (first 200 chars):"
echo "$RESPONSE_BODY" | head -c 200
echo ""

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅✅✅ DeepSeek API IS LIVE AND FUNCTIONAL ✅✅✅"
else
    echo "❌ DeepSeek API returned status: $HTTP_STATUS"
    echo "Full response: $RESPONSE_BODY"
fi

echo ""
echo "=================================================="
echo "TEST 2: Pollo Video API Connectivity"
echo "=================================================="
echo "Endpoint: https://api.piapi.ai/api/v1/task"
echo "Testing video generation - 1 SECOND DURATION FOR COST ⏱️"
echo ""

POLLO_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST "https://api.piapi.ai/api/v1/task" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $POLLO_KEY" \
  -d '{
    "model": "pollo-1.5",
    "task_type": "text2video",
    "input": {
      "prompt": "Test",
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
    echo "⚠️ Pollo API Authentication failed - invalid API key"
    echo "Please check your POLLO_API_KEY in Secrets.xcconfig"
else
    echo "❌ Pollo API returned status: $HTTP_STATUS"
    echo "Full response: $RESPONSE_BODY"
fi

echo ""
echo "=================================================="
echo "🏁 LIVE API TEST COMPLETE"
echo "=================================================="
echo ""
echo "SUMMARY:"
echo "--------"
if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "201" ]; then
    echo "✅ Video Pipeline: READY"
else
    echo "⚠️ Video Pipeline: AUTHENTICATION REQUIRED"
fi

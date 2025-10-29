-- ============================================================
-- UPDATE API KEYS WITH REAL VALUES
-- Replace the placeholders below with your actual API keys
-- ============================================================

-- Replace these placeholder values with your REAL API keys:
-- 
-- 1. Pollo API Key: Get from https://pollo.ai or your Pollo dashboard
-- 2. DeepSeek API Key: Get from https://platform.deepseek.com/api_keys
-- 3. Runway API Key: Get from https://runwayml.com (if using Runway service)

UPDATE api_keys 
SET key = 'YOUR_ACTUAL_POLLO_API_KEY_HERE',
    inserted_at = NOW()
WHERE service = 'Pollo';

UPDATE api_keys 
SET key = 'YOUR_ACTUAL_DEEPSEEK_API_KEY_HERE',
    inserted_at = NOW()
WHERE service = 'DeepSeek';

UPDATE api_keys 
SET key = 'YOUR_ACTUAL_RUNWAY_API_KEY_HERE',
    inserted_at = NOW()
WHERE service = 'Runway';

-- Verify the keys were updated (will show first 15 chars)
SELECT 
    service,
    LEFT(key, 15) || '...' as key_preview,
    LENGTH(key) as key_length,
    CASE 
        WHEN key LIKE 'YOUR_%' THEN '❌ STILL PLACEHOLDER'
        WHEN LENGTH(key) < 20 THEN '⚠️ TOO SHORT'
        ELSE '✅ LOOKS REAL'
    END as status
FROM api_keys
WHERE service IN ('Pollo', 'DeepSeek', 'Runway')
ORDER BY service;

-- After updating, the status should show "✅ LOOKS REAL" for all three


-- ============================================================
-- UPDATE YOUR ACTUAL API KEYS
-- Use dollar-quoting ($key$...$key$) to safely handle special characters
-- Replace the placeholder values below with your real API keys
-- ============================================================

-- Update Pollo API Key
-- Replace YOUR_ACTUAL_POLLO_API_KEY_HERE with your real key between $key$ markers
UPDATE api_keys 
SET key = $key$YOUR_ACTUAL_POLLO_API_KEY_HERE$key$,
    inserted_at = NOW()
WHERE service = 'Pollo';

-- Update DeepSeek API Key
-- Replace YOUR_ACTUAL_DEEPSEEK_API_KEY_HERE with your real key between $key$ markers
UPDATE api_keys 
SET key = $key$YOUR_ACTUAL_DEEPSEEK_API_KEY_HERE$key$,
    inserted_at = NOW()
WHERE service = 'DeepSeek';

-- Verify the keys were updated (should show actual key prefixes, not placeholders)
SELECT 
    service,
    LEFT(key, 20) || '...' as key_preview,
    LENGTH(key) as key_length,
    CASE 
        WHEN key LIKE 'YOUR_%' THEN '⚠️ STILL PLACEHOLDER'
        WHEN LENGTH(key) < 10 THEN '❌ TOO SHORT'
        ELSE '✅ REAL KEY'
    END as status
FROM api_keys
WHERE service IN ('Pollo', 'DeepSeek')
ORDER BY service;

-- Expected: Should see ✅ REAL KEY status for both services
-- The key_preview should show actual API key characters, not "YOUR_..."


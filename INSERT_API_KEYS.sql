-- ============================================================
-- INSERT API KEYS (Additive only - won't update existing)
-- Safe to run if keys don't exist yet
-- ============================================================

-- Insert Pollo API Key (only if it doesn't exist)
-- Replace YOUR_POLLO_API_KEY_HERE with your actual key between $key$ markers
INSERT INTO api_keys (service, key) 
VALUES ('Pollo', $key$YOUR_POLLO_API_KEY_HERE$key$)
ON CONFLICT (service) DO NOTHING;

-- Insert DeepSeek API Key (only if it doesn't exist)
-- Replace YOUR_DEEPSEEK_API_KEY_HERE with your actual key between $key$ markers
INSERT INTO api_keys (service, key) 
VALUES ('DeepSeek', $key$YOUR_DEEPSEEK_API_KEY_HERE$key$)
ON CONFLICT (service) DO NOTHING;

-- Verify
SELECT 
    service,
    LEFT(key, 20) || '...' as key_preview,
    '✅ Inserted' as status
FROM api_keys
WHERE service IN ('Pollo', 'DeepSeek')
ORDER BY service;


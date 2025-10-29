-- ============================================================
-- QUICK FIX for HTTP 400: Check API key/endpoint
-- Run this in Supabase SQL Editor
-- ============================================================

-- STEP 1: Check what's in the table
SELECT 
    service,
    CASE 
        WHEN key IS NULL OR key = '' THEN '❌ EMPTY'
        WHEN LENGTH(key) < 10 THEN '⚠️ TOO SHORT'
        ELSE '✅ OK'
    END as status,
    LEFT(key, 15) || '...' as key_preview
FROM api_keys
ORDER BY service;

-- STEP 2: If missing or empty, INSERT/UPDATE keys
-- REPLACE THE PLACEHOLDERS WITH YOUR ACTUAL API KEYS!
INSERT INTO api_keys (service, key) VALUES 
    ('Pollo', 'YOUR_POLLO_API_KEY_HERE'),
    ('DeepSeek', 'YOUR_DEEPSEEK_API_KEY_HERE'),
    ('Runway', 'YOUR_RUNWAY_API_KEY_HERE')
ON CONFLICT (service) DO UPDATE SET 
    key = EXCLUDED.key,
    inserted_at = NOW();

-- STEP 3: Fix RLS policy (allows app to read keys)
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role only" ON api_keys;
DROP POLICY IF EXISTS "Allow anon read" ON api_keys;

CREATE POLICY "Allow anon read" ON api_keys
    FOR SELECT 
    TO anon
    USING (true);

-- STEP 4: Verify it works
SELECT 
    service,
    LEFT(key, 15) || '...' as key_preview,
    '✅ Found' as status
FROM api_keys
WHERE service IN ('Pollo', 'DeepSeek', 'Runway')
ORDER BY service;

-- Expected: Should see 3 rows with ✅ Found status


-- ============================================================
-- QUICK FIX for HTTP 400: Check API key/endpoint
-- READ-ONLY DIAGNOSTIC QUERIES - Completely safe
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

-- STEP 2: Check existing RLS policies (view only - no changes)
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'api_keys';

-- STEP 3: Verify keys (after you've inserted them via UI or separate script)
SELECT 
    service,
    LEFT(key, 15) || '...' as key_preview,
    '✅ Found' as status
FROM api_keys
WHERE service IN ('Pollo', 'DeepSeek')
ORDER BY service;

-- ============================================================
-- NEXT STEPS:
-- 1. Use the Supabase UI Table Editor to add/update keys:
--    - Go to Table Editor → api_keys
--    - Insert or edit rows for 'Pollo' and 'DeepSeek'
--    - Paste your actual API keys
--
-- OR
--
-- 2. Run INSERT_API_KEYS.sql (only inserts, won't update existing)
-- 3. Run UPDATE_API_KEYS.sql if keys already exist (separate file, safer)
-- 4. Run SETUP_RLS.sql for RLS policy setup (separate file)
-- ============================================================

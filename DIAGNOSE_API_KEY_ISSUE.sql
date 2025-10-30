-- ============================================================
-- COMPREHENSIVE API KEY DIAGNOSTIC
-- Run this to see exactly what's wrong
-- ============================================================

-- 1. Check if keys exist and their exact values
SELECT 
    service,
    LENGTH(key) as key_length,
    LEFT(key, 30) || '...' as key_preview,
    CASE 
        WHEN key IS NULL OR key = '' THEN '❌ EMPTY'
        WHEN key LIKE 'YOUR_%' THEN '⚠️ STILL PLACEHOLDER'
        WHEN LENGTH(key) < 10 THEN '❌ TOO SHORT'
        ELSE '✅ HAS VALUE'
    END as status
FROM api_keys
WHERE service IN ('Pollo', 'DeepSeek')
ORDER BY service;

-- 2. Check RLS status
SELECT 
    tablename,
    CASE 
        WHEN (SELECT relrowsecurity FROM pg_class WHERE relname = 'api_keys') THEN '✅ ENABLED'
        ELSE '❌ DISABLED'
    END as rls_status
FROM pg_tables 
WHERE tablename = 'api_keys';

-- 3. Check RLS policies (THIS IS CRITICAL)
SELECT 
    policyname,
    roles,
    cmd,
    qual,
    CASE 
        WHEN roles = '{anon}' AND cmd = 'SELECT' THEN '✅ CORRECT - Allows anon SELECT'
        ELSE '⚠️ CHECK - May not allow anon SELECT'
    END as policy_status
FROM pg_policies 
WHERE tablename = 'api_keys';

-- 4. Test if we can actually read the keys (simulates what the app does)
-- This should return rows if RLS is working
SELECT 
    service,
    'Readable via RLS' as test_result
FROM api_keys
WHERE service IN ('Pollo', 'DeepSeek');

-- ============================================================
-- EXPECTED RESULTS:
-- 
-- Query 1: Should show ✅ HAS VALUE for both Pollo and DeepSeek
-- Query 2: Should show ✅ ENABLED
-- Query 3: Should show ✅ CORRECT - Allows anon SELECT
-- Query 4: Should return 2 rows
--
-- If Query 3 fails or Query 4 returns 0 rows = RLS policy problem!
-- ============================================================


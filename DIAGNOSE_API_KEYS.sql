-- ============================================================
-- SQL Queries to Diagnose API Key Issues
-- Run these in Supabase SQL Editor: https://supabase.com/dashboard
-- ============================================================

-- ============================================================
-- STEP 1: Check if the table exists and structure
-- ============================================================
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'api_keys'
ORDER BY ordinal_position;

-- Expected output:
-- table_name | column_name  | data_type          | is_nullable
-- api_keys   | service      | text               | NO
-- api_keys   | key          | text               | NO
-- api_keys   | inserted_at | timestamp          | YES


-- ============================================================
-- STEP 2: Check Row Level Security (RLS) status
-- ============================================================
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'api_keys';

-- Expected: Should see a policy "Allow anon read" with:
--   - roles: {anon}
--   - cmd: SELECT
--   - qual: (true)


-- ============================================================
-- STEP 3: Check if RLS is enabled (must be enabled)
-- ============================================================
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public' 
  AND tablename = 'api_keys';

-- Expected: rls_enabled should be TRUE


-- ============================================================
-- STEP 4: List all API keys currently in the table
-- ============================================================
SELECT 
    service,
    LEFT(key, 10) || '...' as key_preview,
    LENGTH(key) as key_length,
    inserted_at,
    CASE 
        WHEN key IS NULL OR key = '' THEN '❌ EMPTY'
        WHEN LENGTH(key) < 10 THEN '⚠️ TOO SHORT'
        ELSE '✅ OK'
    END as status
FROM api_keys
ORDER BY service;

-- Expected: Should see rows for 'Pollo' and 'DeepSeek' with status '✅ OK'


-- ============================================================
-- STEP 5: Test the exact query the app uses
-- ============================================================
-- This simulates what the app does:
-- GET /rest/v1/api_keys?service=eq.Pollo&select=key

SELECT key 
FROM api_keys 
WHERE service = 'Pollo';

-- Expected: Should return exactly one row with a valid API key

SELECT key 
FROM api_keys 
WHERE service = 'DeepSeek';

-- Expected: Should return exactly one row with a valid API key


-- ============================================================
-- STEP 6: Check for common issues
-- ============================================================

-- Issue 1: Missing keys
SELECT 
    'Missing' as issue,
    service_name
FROM (
    VALUES ('Pollo'), ('DeepSeek')
) AS required_services(service_name)
WHERE NOT EXISTS (
    SELECT 1 FROM api_keys 
    WHERE api_keys.service = required_services.service_name
);

-- Issue 2: Empty keys
SELECT 
    'Empty' as issue,
    service
FROM api_keys
WHERE key IS NULL OR TRIM(key) = '';

-- Issue 3: Wrong service name casing
SELECT 
    'Wrong casing' as issue,
    service
FROM api_keys
WHERE service NOT IN ('Pollo', 'DeepSeek');

-- Issue 4: Check for extra spaces
SELECT 
    'Has spaces' as issue,
    service,
    LENGTH(service) as length_with_spaces,
    LENGTH(TRIM(service)) as length_trimmed
FROM api_keys
WHERE LENGTH(service) != LENGTH(TRIM(service));


-- ============================================================
-- STEP 7: Fix Common Issues
-- ============================================================

-- Fix 1: Create table if missing (should already exist)
CREATE TABLE IF NOT EXISTS api_keys (
    service TEXT PRIMARY KEY,
    key TEXT NOT NULL,
    inserted_at TIMESTAMP DEFAULT NOW()
);

-- Fix 2: Enable RLS if disabled
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

-- Fix 3: Fix RLS policy (drop old, create new)
DROP POLICY IF EXISTS "Service role only" ON api_keys;
DROP POLICY IF EXISTS "Allow anon read" ON api_keys;

CREATE POLICY "Allow anon read" ON api_keys
    FOR SELECT 
    TO anon
    USING (true);

-- Fix 4: Insert/Update API keys (REPLACE WITH YOUR ACTUAL KEYS!)
INSERT INTO api_keys (service, key) VALUES 
    ('Pollo', 'YOUR_POLLO_API_KEY_HERE'),
    ('DeepSeek', 'YOUR_DEEPSEEK_API_KEY_HERE')
ON CONFLICT (service) DO UPDATE SET 
    key = EXCLUDED.key,
    inserted_at = NOW();

-- Fix 5: Remove any keys with wrong casing/spaces
DELETE FROM api_keys 
WHERE TRIM(LOWER(service)) NOT IN ('pollo', 'deepseek');

-- Fix 6: Update existing keys with trimmed service names
UPDATE api_keys 
SET service = TRIM(service)
WHERE service != TRIM(service);


-- ============================================================
-- STEP 8: Verify the fix worked
-- ============================================================
-- Run this after fixes to confirm everything is working

SELECT 
    '✅ FIXED' as status,
    service,
    CASE 
        WHEN LENGTH(key) > 20 THEN LEFT(key, 15) || '...'
        ELSE key
    END as key_preview,
    inserted_at
FROM api_keys
WHERE service IN ('Pollo', 'DeepSeek')
ORDER BY service;

-- Expected: Should see 2 rows with valid keys


-- ============================================================
-- STEP 9: Test with exact service names the app expects
-- ============================================================
-- The app queries these exact strings:
-- - "Pollo" (exact match, case-sensitive)
-- - "DeepSeek" (exact match, case-sensitive)

SELECT 
    service,
    CASE 
        WHEN service = 'Pollo' THEN '✅ Pollo matches'
        WHEN service = 'DeepSeek' THEN '✅ DeepSeek matches'
        ELSE '❌ Wrong service name'
    END as match_status,
    CASE 
        WHEN key IS NULL OR key = '' THEN '❌ Key is empty'
        WHEN LENGTH(key) < 10 THEN '⚠️ Key looks invalid'
        ELSE '✅ Key looks valid'
    END as key_status
FROM api_keys
WHERE service IN ('Pollo', 'DeepSeek');

-- Expected: Both should show ✅ matches and ✅ valid keys


-- ============================================================
-- STEP 10: Check RLS policy permissions
-- ============================================================
-- Verify anon role can read

SET ROLE anon;
SELECT service, LEFT(key, 5) || '...' as key_preview 
FROM api_keys 
WHERE service = 'Pollo';
RESET ROLE;

-- Expected: Should return one row (if RLS is correct)


-- ============================================================
-- COMMON ERROR SCENARIOS & FIXES
-- ============================================================

-- Scenario 1: HTTP 400 - Bad Request
-- CAUSE: RLS policy blocks access OR service name doesn't match
-- FIX: Run Fix 2 and Fix 3 above

-- Scenario 2: HTTP 401 - Unauthorized  
-- CAUSE: Supabase anon key is wrong in app code
-- FIX: Check SupabaseAPIKeyService.swift line 14

-- Scenario 3: HTTP 404 - Not Found
-- CAUSE: Table doesn't exist OR no row for service
-- FIX: Run Fix 1 and Fix 4 above

-- Scenario 4: Empty response array []
-- CAUSE: Service name mismatch (case/typo)
-- FIX: Run Fix 5 above, then Fix 4 with correct names

-- Scenario 5: Key returned but API still rejects
-- CAUSE: Invalid API key OR wrong endpoint URL
-- FIX: Verify key is correct in Pollo/DeepSeek dashboard


-- ============================================================
-- QUICK DEBUG CHECKLIST
-- ============================================================
-- Run Steps 1-5 first to diagnose, then:
-- ✅ Table exists? (Step 1)
-- ✅ RLS enabled? (Step 3)  
-- ✅ Policy allows anon read? (Step 2)
-- ✅ Keys exist for 'Pollo' and 'DeepSeek'? (Step 4)
-- ✅ Query returns key? (Step 5)
-- ✅ Service names match exactly? (Step 9)


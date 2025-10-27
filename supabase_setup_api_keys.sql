-- ============================================================
-- Setup API Keys in Supabase
-- Run this in Supabase SQL Editor to enable API key access
-- ============================================================

-- Step 1: Fix the RLS policy (if you haven't already run the migration)
-- Drop old policy if it exists
DROP POLICY IF EXISTS "Service role only" ON api_keys;

-- Create new policy to allow anon users to read API keys
CREATE POLICY "Allow anon read" ON api_keys
  FOR SELECT 
  TO anon
  USING (true);

-- Step 2: Insert your API keys
-- Replace the placeholder values with your actual API keys!

INSERT INTO api_keys (service, key) VALUES 
    ('Pollo', 'YOUR_POLLO_API_KEY_HERE'),
    ('DeepSeek', 'YOUR_DEEPSEEK_API_KEY_HERE')
ON CONFLICT (service) DO UPDATE SET key = EXCLUDED.key;

-- Step 3: Verify the keys were inserted
SELECT service, 
       LEFT(key, 10) || '...' as key_preview,
       inserted_at 
FROM api_keys;

-- Expected output:
-- service   | key_preview | inserted_at
-- ----------|-------------|-------------
-- Pollo     | YOUR_POLLO_... | 2024-...
-- DeepSeek  | YOUR_DEEPSEEK_... | 2024-...

-- ============================================================
-- Troubleshooting
-- ============================================================

-- If you get "permission denied", check if RLS is enabled:
-- SELECT * FROM pg_policies WHERE tablename = 'api_keys';

-- If you need to update an existing key:
-- UPDATE api_keys SET key = 'your-new-key' WHERE service = 'Pollo';

-- If you need to delete a key:
-- DELETE FROM api_keys WHERE service = 'Pollo';

-- ============================================================
-- Security Note
-- ============================================================
-- These API keys will be readable by the app, but that's safe because:
-- 1. They're stored on the server (Supabase), not in the app binary
-- 2. Keys can be rotated without updating the app
-- 3. Only SELECT permission is granted, not INSERT/UPDATE/DELETE
-- 4. Keys are cached in memory and cleared on app restart


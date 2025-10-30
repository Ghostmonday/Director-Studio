-- ============================================================
-- SETUP ROW LEVEL SECURITY (RLS) POLICIES
-- Run this separately after inserting/updating keys
-- ============================================================

-- Enable RLS (idempotent - safe to run multiple times)
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

-- Create read policy for anon users (only if it doesn't exist)
-- Note: If policy already exists, this will fail - that's OK, it means it's already set up
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'api_keys' 
        AND policyname = 'Allow anon read'
    ) THEN
        CREATE POLICY "Allow anon read" ON api_keys
            FOR SELECT 
            TO anon
            USING (true);
        RAISE NOTICE 'Policy "Allow anon read" created successfully';
    ELSE
        RAISE NOTICE 'Policy "Allow anon read" already exists - no action needed';
    END IF;
END $$;

-- Verify policy was created
SELECT 
    policyname,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'api_keys';


-- Insert Kling AI credentials into api_keys table
-- AccessKey and SecretKey stored as separate service entries

-- Insert Kling AccessKey
INSERT INTO api_keys (service, key)
VALUES ('Kling', 'AaGFBM9CyHL8k4B43kFMLD9a4k9CGhgg')
ON CONFLICT (service) 
DO UPDATE SET key = EXCLUDED.key, inserted_at = NOW();

-- Insert Kling SecretKey
INSERT INTO api_keys (service, key)
VALUES ('KlingSecret', 'GaJFMP43TkEmy8JfP3KQpTd43khAfLhY')
ON CONFLICT (service) 
DO UPDATE SET key = EXCLUDED.key, inserted_at = NOW();

-- Verify insertion
SELECT service, LEFT(key, 12) || '...' as key_preview, inserted_at 
FROM api_keys 
WHERE service IN ('Kling', 'KlingSecret');


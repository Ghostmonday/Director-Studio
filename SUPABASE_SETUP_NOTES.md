# 📋 Supabase Setup Notes

## Hosted Instance Configuration

Your app is now configured to use:
- **URL**: `https://carkncjucvtbggqrilwj.supabase.co`
- **Anon Key**: Embedded in `SupabaseAPIKeyService.swift` (needs to be updated)

## Database Setup Required

Make sure your Supabase instance has:

### 1. Create the `api_keys` table:
```sql
CREATE TABLE IF NOT EXISTS api_keys (
    service TEXT PRIMARY KEY,
    key TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### 2. Insert your API keys:
```sql
INSERT INTO api_keys (service, key) VALUES 
    ('Pollo', 'your-actual-pollo-key'),
    ('DeepSeek', 'your-actual-deepseek-key')
ON CONFLICT (service) DO UPDATE SET key = EXCLUDED.key;
```

### 3. Enable Row Level Security (RLS):
```sql
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

-- Allow anon users to read API keys (secure because keys are server-side only)
CREATE POLICY "Allow anon read" ON api_keys
    FOR SELECT 
    TO anon
    USING (true);
```

## Testing the Connection

Run the test script:
```bash
cd /Users/user944529/Desktop/last-try
swift test_supabase_connection.swift
```

## In the App

The service is already integrated. When you create a video:
- It will fetch keys from your hosted Supabase
- You'll see: `🔑 Fetching Pollo key from hosted Supabase...`
- Keys are cached for the session

## Security Notes

- The anon key is safe to embed in the app
- API keys are only readable, not writable
- Consider adding authenticated access later
- Keys are cached in memory, cleared on app restart

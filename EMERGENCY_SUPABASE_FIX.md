# 🚨 EMERGENCY: Fix HTTP 400 API Key Error

## Problem
Getting HTTP 400 when trying to fetch API keys from Supabase.

**Root Cause**: Database table doesn't exist OR API keys aren't inserted.

---

## ⚡ INSTANT FIX (3 minutes)

### Step 1: Apply Migration
Go to your Supabase dashboard and run this SQL:

**URL**: https://supabase.com/dashboard/project/carkncjucvtbggqrilwj/sql

```sql
-- Create api_keys table
CREATE TABLE IF NOT EXISTS api_keys (
  service TEXT PRIMARY KEY,
  key TEXT NOT NULL,
  inserted_at TIMESTAMP DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

-- Drop old policy if exists
DROP POLICY IF EXISTS "Allow anon read" ON api_keys;

-- Allow anon users to read API keys
CREATE POLICY "Allow anon read" ON api_keys
  FOR SELECT 
  TO anon
  USING (true);
```

---

### Step 2: Insert Your API Keys
**REPLACE WITH YOUR ACTUAL KEYS**:

```sql
-- Clear any old keys
TRUNCATE TABLE api_keys;

-- Insert Pollo API key
INSERT INTO api_keys (service, key)
VALUES ('Pollo', 'YOUR_POLLO_API_KEY_HERE')
ON CONFLICT (service) DO UPDATE SET key = EXCLUDED.key;

-- Insert DeepSeek API key
INSERT INTO api_keys (service, key)
VALUES ('DeepSeek', 'YOUR_DEEPSEEK_API_KEY_HERE')
ON CONFLICT (service) DO UPDATE SET key = EXCLUDED.key;
```

**Example** (with fake keys):
```sql
INSERT INTO api_keys (service, key)
VALUES ('Pollo', 'pollo_sk_1234567890abcdef')
ON CONFLICT (service) DO UPDATE SET key = EXCLUDED.key;

INSERT INTO api_keys (service, key)
VALUES ('DeepSeek', 'sk-proj-1234567890abcdef')
ON CONFLICT (service) DO UPDATE SET key = EXCLUDED.key;
```

---

### Step 3: Verify It Works
Run this SQL to check:

```sql
SELECT service, LEFT(key, 10) || '...' as key_preview, inserted_at
FROM api_keys;
```

**Expected output**:
```
service  | key_preview    | inserted_at
---------|----------------|------------------
Pollo    | pollo_sk_1...  | 2025-10-27 ...
DeepSeek | sk-proj-1...   | 2025-10-27 ...
```

---

### Step 4: Test from App
Run the app again and check console output:

**Expected**:
```
🔑 Fetching Pollo key from hosted Supabase...
✅ Successfully fetched Pollo key from hosted Supabase
```

**NOT**:
```
❌ Failed to fetch Pollo key: HTTP 400
```

---

## 🎯 Quick Checklist

- [ ] SQL migration applied (table created)
- [ ] RLS policy created
- [ ] API keys inserted
- [ ] Keys verified with SELECT query
- [ ] App tested - no more HTTP 400

---

## 🔍 Troubleshooting

### Still getting HTTP 400?
Check the exact error response:

```swift
// Add to SupabaseAPIKeyService.swift line 48
print("❌ Response body: \(String(data: data, encoding: .utf8) ?? "none")")
```

### Getting HTTP 401?
- Anon key is wrong
- RLS policy not applied

### Getting empty array?
- Keys not inserted
- Service name mismatch (case-sensitive: "Pollo" not "pollo")

---

## 💡 Where to Find Your API Keys

**Pollo API**: https://api.pollo.ai/dashboard (or wherever you signed up)
**DeepSeek API**: https://platform.deepseek.com/api_keys

If you don't have these yet, the app will fall back to **demo mode** (which works but shows placeholder videos).

---

**Once fixed, you can proceed with the phased submission plan!** 🚀


# ✅ Next Steps: Complete Supabase Setup

## What I Just Fixed

✅ Updated Supabase URL from `xduwbxbulphvuqqfjrec` to `carkncjucvtbggqrilwj` in:
- `DirectorStudio/Services/SupabaseAPIKeyService.swift`
- `test_supabase_connection.swift`
- `API_AUDIT_SUMMARY.md`
- `QUICK_FIX_API_KEYS.md`
- `SUPABASE_SETUP_NOTES.md`

---

## 🔴 Action Required: Update Anon Key

You need to update the Supabase anon key in `DirectorStudio/Services/SupabaseAPIKeyService.swift`.

### Steps:

1. **Get your anon key from Supabase:**
   - Go to https://supabase.com/dashboard
   - Select project: `carkncjucvtbggqrilwj`
   - Go to **Settings** → **API**
   - Copy the **anon/public** key

2. **Update the file:**
   - Open `DirectorStudio/Services/SupabaseAPIKeyService.swift`
   - Replace `YOUR_ANON_KEY_HERE` on line 14 with your actual anon key

---

## 🔴 Action Required: Setup Database

Run this SQL in your Supabase project:

### Step 1: Create Table (if not exists)

```sql
CREATE TABLE IF NOT EXISTS api_keys (
    service TEXT PRIMARY KEY,
    key TEXT NOT NULL,
    inserted_at TIMESTAMP DEFAULT NOW()
);
```

### Step 2: Fix RLS Policy

```sql
-- Drop old policy if exists
DROP POLICY IF EXISTS "Service role only" ON api_keys;

-- Create new policy
CREATE POLICY "Allow anon read" ON api_keys
  FOR SELECT 
  TO anon
  USING (true);
```

### Step 3: Insert Your API Keys

```sql
INSERT INTO api_keys (service, key) VALUES 
    ('Pollo', 'your-actual-pollo-api-key'),
    ('DeepSeek', 'your-actual-deepseek-api-key')
ON CONFLICT (service) DO UPDATE SET key = EXCLUDED.key;
```

**⚠️ Replace the placeholder keys with your real API keys!**

---

## ✅ Verify Setup

After completing the above steps, test the connection:

```bash
cd /Users/user944529/Desktop/last-try
swift test_supabase_connection.swift
```

Expected output:
```
🧪 Testing Supabase Connection...
==================================================
🔑 Fetching Pollo key from hosted Supabase...
✅ Pollo API Key: pollo_123...
🔑 Fetching DeepSeek key from hosted Supabase...
✅ DeepSeek API Key: sk-proj_123...
==================================================
🎉 Test complete!
```

---

## 📋 Summary

| Task | Status | File |
|------|--------|------|
| Update Supabase URL | ✅ Done | `SupabaseAPIKeyService.swift` |
| Update anon key | ⏳ **You need to do this** | `SupabaseAPIKeyService.swift` |
| Create database table | ⏳ **You need to do this** | Run SQL in Supabase |
| Fix RLS policy | ⏳ **You need to do this** | Run SQL in Supabase |
| Insert API keys | ⏳ **You need to do this** | Run SQL in Supabase |

---

## 🆘 Troubleshooting

### If you get "Invalid anon key" error:
- Make sure you copied the entire anon key (it's a long JWT token)
- Check that there are no extra spaces

### If you get "HTTP 403" error:
- The RLS policy wasn't applied yet
- Re-run the RLS policy SQL

### If you get "No API key found":
- The keys weren't inserted into the database
- Run the INSERT SQL statement

---

**Ready to go?** Complete the 2 action items above and your API keys will work! 🚀


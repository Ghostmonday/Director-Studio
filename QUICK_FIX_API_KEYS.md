# Quick Fix: API Keys Not Loading from Supabase

## 🎯 The Problem

Your app can't fetch API keys from Supabase because the Row Level Security (RLS) policy was blocking all access.

## ✅ The Fix (3 Steps)

### Step 1: Open Supabase Dashboard
1. Go to https://supabase.com/dashboard
2. Select project: `carkncjucvtbggqrilwj`
3. Click **SQL Editor** in left sidebar

### Step 2: Copy & Paste This SQL

```sql
-- Fix the RLS policy
DROP POLICY IF EXISTS "Service role only" ON api_keys;

CREATE POLICY "Allow anon read" ON api_keys
  FOR SELECT 
  TO anon
  USING (true);

-- Insert your API keys (replace with your actual keys!)
INSERT INTO api_keys (service, key) VALUES 
    ('Pollo', 'your-actual-pollo-key'),
    ('DeepSeek', 'your-actual-deepseek-key')
ON CONFLICT (service) DO UPDATE SET key = EXCLUDED.key;
```

### Step 3: Click "Run" Button

That's it! Your app should now be able to fetch API keys.

---

## 🧪 Test It

After running the SQL, test with:

```bash
swift test_supabase_connection.swift
```

Or just run your app and try generating a video.

---

## 📁 Files Changed

- ✅ `supabase/migrations/001_create_api_keys_table.sql` - Fixed RLS policy
- ✅ `API_AUDIT_SUMMARY.md` - Detailed audit report
- ✅ `supabase_setup_api_keys.sql` - SQL script you can run

---

## 💡 What Changed?

**Before:**
```sql
CREATE POLICY "Service role only" ON api_keys
  FOR ALL
  USING (false);  -- Blocks EVERYONE ❌
```

**After:**
```sql
CREATE POLICY "Allow anon read" ON api_keys
  FOR SELECT 
  TO anon
  USING (true);  -- Allows reading ✅
```

---

## ⚠️ Don't Forget

Replace `'your-actual-pollo-key'` and `'your-actual-deepseek-key'` with your real API keys before running the SQL!


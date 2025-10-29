# API Keys Explained

## Each Service Needs Its Own Key

DirectorStudio uses **3 different AI services**, each requiring a **separate API key**:

### 1. **Pollo** (Primary Video Generation)
- **Service Name in Database:** `"Pollo"` (exact match, case-sensitive)
- **Where to Get Key:** https://pollo.ai → Dashboard → API Keys
- **Used For:** Main video generation (text-to-video)
- **Database Query:** `SELECT key FROM api_keys WHERE service = 'Pollo'`

### 2. **DeepSeek** (Text Enhancement)
- **Service Name in Database:** `"DeepSeek"` (exact match, case-sensitive)
- **Where to Get Key:** https://platform.deepseek.com → API Keys
- **Used For:** Prompt enhancement and optimization
- **Database Query:** `SELECT key FROM api_keys WHERE service = 'DeepSeek'`

### 3. **Runway** (Alternative Video Generation)
- **Service Name in Database:** `"Runway"` (exact match, case-sensitive)
- **Where to Get Key:** https://runwayml.com → API Settings
- **Used For:** Alternative video generation (if Pollo unavailable)
- **Database Query:** `SELECT key FROM api_keys WHERE service = 'Runway'`

---

## Key Differences

| Service | API Provider | Purpose | Required? |
|---------|-------------|---------|-----------|
| **Pollo** | Pollo AI | Main video generation | ✅ Yes (primary) |
| **DeepSeek** | DeepSeek AI | Text enhancement | ✅ Yes (recommended) |
| **Runway** | Runway ML | Backup video generation | ⚠️ Optional |

---

## Why Different Keys?

Each service is a **different company/product**:
- **Pollo AI** = One company, needs Pollo account & key
- **DeepSeek** = Different company, needs DeepSeek account & key  
- **Runway ML** = Different company, needs Runway account & key

You can't use a Pollo key for Runway, or vice versa. Each API validates its own keys.

---

## How to Set Up All 3 Keys

### Step 1: Get Your API Keys

1. **Pollo:** Sign up at https://pollo.ai → Get API key
2. **DeepSeek:** Sign up at https://platform.deepseek.com → Get API key
3. **Runway:** Sign up at https://runwayml.com → Get API key (optional)

### Step 2: Insert Into Supabase

Run this SQL in Supabase SQL Editor:

```sql
-- Insert all three keys (replace with YOUR actual keys)
INSERT INTO api_keys (service, key) VALUES 
    ('Pollo', 'sk-pollo-YOUR-ACTUAL-POLLO-KEY'),
    ('DeepSeek', 'sk-YOUR-ACTUAL-DEEPSEEK-KEY'),
    ('Runway', 'YOUR-ACTUAL-RUNWAY-KEY')
ON CONFLICT (service) DO UPDATE SET 
    key = EXCLUDED.key,
    inserted_at = NOW();
```

### Step 3: Verify All Three Are Set

```sql
SELECT 
    service,
    LEFT(key, 20) || '...' as key_preview,
    CASE 
        WHEN key LIKE 'YOUR_%' OR key LIKE 'sk-%' AND LENGTH(key) < 30 THEN '❌ INVALID'
        ELSE '✅ VALID'
    END as status
FROM api_keys
WHERE service IN ('Pollo', 'DeepSeek', 'Runway')
ORDER BY service;
```

---

## Minimum Required Keys

**At minimum, you need:**
- ✅ **Pollo** key (required - main video generation)
- ✅ **DeepSeek** key (recommended - prompt enhancement)

**Optional:**
- ⚠️ **Runway** key (only if you want backup video generation)

---

## Current Status

Based on your query results, you have:
- ✅ All 3 services in database
- ❌ All 3 still have placeholder keys (`YOUR_POLLO_API_...`, etc.)

**Next Step:** Replace placeholders with real API keys from each provider.


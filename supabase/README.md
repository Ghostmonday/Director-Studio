# Supabase Backend Setup

## 📋 Prerequisites

```bash
# Install Supabase CLI
npm install -g supabase
```

---

## 🚀 Quick Start

### 1. Initialize Supabase (if not already done)

```bash
cd /Users/user944529/Desktop/last-try
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```

Get `YOUR_PROJECT_REF` from: Supabase Dashboard → Settings → API → Project URL

---

### 2. Create Database Table

Go to Supabase Dashboard → SQL Editor → New Query:

```sql
-- Create api_keys table
CREATE TABLE IF NOT EXISTS api_keys (
  service TEXT PRIMARY KEY,
  key TEXT NOT NULL,
  inserted_at TIMESTAMP DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

-- Only service role can access
CREATE POLICY "Service role only" ON api_keys
  FOR ALL
  USING (false);
```

Click **Run**.

---

### 3. Insert Your API Keys

In Supabase Dashboard → SQL Editor:

```sql
-- Insert Pollo API key
INSERT INTO api_keys (service, key)
VALUES ('Pollo', 'sk-your-pollo-key-here');

-- Insert DeepSeek API key
INSERT INTO api_keys (service, key)
VALUES ('DeepSeek', 'sk-your-deepseek-key-here');
```

**Replace with your actual keys!**

---

### 4. Deploy Edge Function

```bash
cd /Users/user944529/Desktop/last-try

# Deploy the function
supabase functions deploy generate-api-key

# Set environment variables for local testing
export POLLO_API_KEY=sk-your-pollo-key
export DEEPSEEK_API_KEY=sk-your-deepseek-key
```

---

## 🧪 Testing

### Test Locally

```bash
# Serve function locally
supabase functions serve generate-api-key --env-file .env.local

# In another terminal, test it:
curl -X POST http://127.0.0.1:54321/functions/v1/generate-api-key \
  -H "Authorization: Bearer YOUR_USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"service": "Pollo"}'
```

### Test Production

```bash
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/generate-api-key \
  -H "Authorization: Bearer YOUR_USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"service": "Pollo"}'
```

Expected response:
```json
{
  "key": "sk-your-pollo-key..."
}
```

---

## 📱 iOS Integration

Update `PolloAIService.swift`:

```swift
func getAPIKey() async throws -> String {
    let url = URL(string: "https://YOUR_PROJECT.supabase.co/functions/v1/generate-api-key")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    // Get user's auth token
    let token = try await supabase.auth.session.accessToken
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // Request Pollo key
    let body = ["service": "Pollo"]
    request.httpBody = try JSONEncoder().encode(body)
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let response = try JSONDecoder().decode([String: String].self, from: data)
    
    return response["key"]!
}
```

---

## 🔐 Security

✅ **API keys stored in database** (encrypted at rest)  
✅ **Only authenticated users can request keys**  
✅ **Keys never exposed in app binary**  
✅ **Row Level Security enabled**  

---

## 📊 Monitoring

Check Supabase Dashboard → Edge Functions → Logs to see:
- Request counts
- Errors
- Response times

---

## 🆘 Troubleshooting

**"Service role key not found"**
- Make sure you've deployed: `supabase functions deploy`

**"Not found" error**
- Verify keys exist: `SELECT * FROM api_keys;` in SQL Editor

**"Unauthorized"**
- Check user is logged in
- Verify auth token is valid

---

## 🔄 Update Keys

```sql
-- Update existing key
UPDATE api_keys
SET key = 'sk-new-key-here'
WHERE service = 'Pollo';
```

---

Done! Your API keys are now secure. 🔒


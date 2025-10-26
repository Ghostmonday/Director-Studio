# 🚀 **DirectorStudio Backend Deployment Guide**

---

## ⚡ **Quick Deploy (15 minutes)**

### **Step 1: Create Supabase Account**

1. Go to https://supabase.com
2. Click **"Start your project"**
3. Sign in with GitHub
4. Create new project:
   - **Name**: DirectorStudio
   - **Region**: Choose closest to you
   - **Database Password**: Save this!

**Wait 2-3 minutes** for project to provision.

---

### **Step 2: Set Up Database**

1. Go to **SQL Editor** in left sidebar
2. Click **"New Query"**
3. Paste this:

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

4. Click **Run** (bottom right)
5. Should see: ✅ **"Success. No rows returned"**

---

### **Step 3: Add Your API Keys**

Still in SQL Editor, **New Query**:

```sql
-- Insert Pollo API key
INSERT INTO api_keys (service, key)
VALUES ('Pollo', 'YOUR_POLLO_KEY_HERE');

-- Insert DeepSeek API key  
INSERT INTO api_keys (service, key)
VALUES ('DeepSeek', 'YOUR_DEEPSEEK_KEY_HERE');
```

**Replace** `YOUR_POLLO_KEY_HERE` with your actual Pollo API key!

Click **Run**.

---

### **Step 4: Deploy Edge Function**

#### **4A: Install Supabase CLI**

**If you have permission issues with Homebrew:**

```bash
# Download binary directly
curl -L https://github.com/supabase/cli/releases/latest/download/supabase_darwin_arm64.tar.gz -o supabase.tar.gz
tar -xzf supabase.tar.gz
sudo mv supabase /usr/local/bin/
supabase --version
```

#### **4B: Login & Link**

```bash
cd /Users/user944529/Desktop/last-try

# Login
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF
```

**Get `YOUR_PROJECT_REF`:**
- Supabase Dashboard → Settings → API
- Look at **"Project URL"**: `https://XXXXX.supabase.co`
- The `XXXXX` part is your project ref

#### **4C: Deploy Function**

```bash
supabase functions deploy generate-api-key
```

Should see: ✅ **"Deployed function generate-api-key"**

---

### **Step 5: Test It**

Get a test user token:

1. Supabase Dashboard → **Authentication** → **Users**
2. Create a test user (if none exist)
3. Copy the **"Access Token"** (or use SDK to sign in)

Test the function:

```bash
curl -X POST https://YOUR_PROJECT_REF.supabase.co/functions/v1/generate-api-key \
  -H "Authorization: Bearer YOUR_USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"service": "Pollo"}'
```

Should return:
```json
{
  "key": "sk-your-pollo-key..."
}
```

---

### **Step 6: Update iOS App**

Create `DirectorStudio/Services/SupabaseAPIKeyService.swift`:

```swift
import Foundation

class SupabaseAPIKeyService {
    static let shared = SupabaseAPIKeyService()
    private let supabaseURL = "https://YOUR_PROJECT_REF.supabase.co"
    
    func getAPIKey(service: String) async throws -> String {
        let url = URL(string: "\(supabaseURL)/functions/v1/generate-api-key")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Get user's auth token (you'll need to implement this)
        // For dev mode, we'll use a placeholder
        request.setValue("Bearer dev-token", forHTTPHeaderField: "Authorization")
        
        let body = ["service": service]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "SupabaseAPI", code: -1)
        }
        
        let result = try JSONDecoder().decode([String: String].self, from: data)
        return result["key"] ?? ""
    }
}
```

Update `PolloAIService.swift`:

```swift
public func generateVideo(prompt: String, duration: TimeInterval) async throws -> URL {
    // Get API key from Supabase
    let apiKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "Pollo")
    
    // Use the key
    let url = URL(string: "\(endpoint)/video/generate")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    // ... rest of generation code
}
```

---

### **Step 7: Rebuild & Test**

```bash
cd /Users/user944529/Desktop/last-try

# Clean build
xcodebuild clean -scheme DirectorStudio

# Build
xcodebuild -scheme DirectorStudio -destination 'platform=iOS Simulator,id=12673044-36F5-49BF-9242-4BE668CAC291' build

# Install
xcrun simctl install 12673044-36F5-49BF-9242-4BE668CAC291 ~/Library/Developer/Xcode/DerivedData/DirectorStudio-*/Build/Products/Debug-iphonesimulator/DirectorStudio.app

# Launch
xcrun simctl launch 12673044-36F5-49BF-9242-4BE668CAC291 com.directorstudio.app
```

---

## ✅ **Verification Checklist**

- [ ] Supabase project created
- [ ] Database table `api_keys` exists
- [ ] API keys inserted (Pollo & DeepSeek)
- [ ] Edge function deployed
- [ ] Function test returns key
- [ ] iOS app updated with Supabase service
- [ ] App rebuilt
- [ ] Video generation uses real API

---

## 🆘 **Troubleshooting**

### **"Permission denied" on Homebrew**
```bash
# Use direct binary download (see Step 4A)
```

### **"Project ref not found"**
```bash
# Get it from: Dashboard → Settings → API → Project URL
```

### **"Unauthorized" from function**
```bash
# Make sure user is authenticated
# Check Authorization header has valid token
```

### **"Keys not working in app"**
```bash
# Verify keys in database: SELECT * FROM api_keys;
# Test function directly with curl
```

---

## 🎯 **Next Steps After Deployment**

1. **Remove demo mode** from app
2. **Add authentication** (Supabase Auth)
3. **Implement credit system** (StoreKit + Supabase)
4. **Add monitoring** (Supabase Dashboard → Functions → Logs)

---

## 🔐 **Security Notes**

✅ **API keys NEVER in app code**  
✅ **Keys stored in Supabase database (encrypted at rest)**  
✅ **Only authenticated users can request keys**  
✅ **Row Level Security prevents direct access**  

---

**Need help? Check `supabase/README.md` for detailed docs.**


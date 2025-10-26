# 🚀 Quick Backend Setup for DirectorStudio

## Prerequisites
- Docker Desktop installed and running
- Your Pollo AI API key
- Your DeepSeek API key (optional)

## Step-by-Step Commands

### 1. Install Docker Desktop
Download from: https://www.docker.com/products/docker-desktop/

### 2. Install Supabase CLI
```bash
brew install supabase/tap/supabase
```

### 3. Start Supabase
```bash
cd /Users/user944529/Desktop/last-try
supabase start
```

### 4. Add Your API Keys
```bash
# Connect to the database
psql "postgresql://postgres:postgres@localhost:54322/postgres"
```

Then paste this SQL (replace with your actual keys):
```sql
INSERT INTO api_keys (service, key) VALUES 
  ('Pollo', 'YOUR_ACTUAL_POLLO_API_KEY_HERE'),
  ('DeepSeek', 'YOUR_ACTUAL_DEEPSEEK_KEY_HERE')
ON CONFLICT (service) DO UPDATE SET key = EXCLUDED.key;

-- Verify
SELECT * FROM api_keys;

-- Exit psql
\q
```

### 5. Test in the App
1. Force quit the DirectorStudio app (if running)
2. Launch it again from Xcode (⌘+R)
3. Try creating a video - it should now use your real API!

## Troubleshooting

### If Docker won't start:
- Make sure you have at least 4GB free disk space
- Restart your Mac

### If Supabase fails:
```bash
# Stop and clean
supabase stop
docker system prune -a

# Try again
supabase start
```

### If API calls fail:
Check the Xcode console for errors. The app will show:
- "🔑 Using Supabase Pollo key" = Good! 
- "🔑 Using local Pollo key" = Using demo mode

## URLs
- Supabase Studio: http://localhost:54323
- API Endpoint: http://localhost:54321
- See all running services: `supabase status`

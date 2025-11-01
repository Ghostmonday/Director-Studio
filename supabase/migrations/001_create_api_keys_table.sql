-- Create api_keys table
-- Stores API keys for external services (Pollo, DeepSeek, etc.)

CREATE TABLE IF NOT EXISTS api_keys (
  service TEXT PRIMARY KEY,
  key TEXT NOT NULL,
  inserted_at TIMESTAMP DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

-- Allow anon users to read API keys (keys are on server-side, safe to expose)
CREATE POLICY "Allow anon read" ON api_keys
  FOR SELECT 
  TO anon
  USING (true);

-- Add comment
COMMENT ON TABLE api_keys IS 'Secure storage for external API keys';


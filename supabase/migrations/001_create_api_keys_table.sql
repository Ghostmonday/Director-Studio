-- Create api_keys table
-- Stores API keys for external services (Pollo, DeepSeek, etc.)

CREATE TABLE IF NOT EXISTS api_keys (
  service TEXT PRIMARY KEY,
  key TEXT NOT NULL,
  inserted_at TIMESTAMP DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

-- Only service role can access (no user access)
CREATE POLICY "Service role only" ON api_keys
  FOR ALL
  USING (false);

-- Add comment
COMMENT ON TABLE api_keys IS 'Secure storage for external API keys';


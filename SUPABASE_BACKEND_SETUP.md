# 🎯 **Step-by-Step Monetization System Build Guide**
### *Copy-Paste Friendly Edition*

---

## 📋 **PHASE 1: Database Tables (30 mins)**

### **Step 1.1: Create Core Tables**
Go to Supabase → SQL Editor → New Query → Paste this:

```sql
-- Users table (probably already exists, but here's the full version)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  stripe_customer_id TEXT UNIQUE,
  subscription_plan TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Video generations table
CREATE TABLE video_generations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  duration_seconds FLOAT NOT NULL,
  model_tier TEXT NOT NULL CHECK (model_tier IN ('standard', 'pro', 'ultra')),
  quality_tier TEXT NOT NULL CHECK (quality_tier IN ('watermark', 'standard', 'hd', 'ultra_hd', 'studio')),
  multiplier FLOAT NOT NULL,
  cost_usd NUMERIC(10,2) NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'success', 'failed')),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Token purchases table
CREATE TABLE token_purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  bundle_size_seconds INT NOT NULL,
  price_usd NUMERIC(10,2) NOT NULL,
  stripe_tx_id TEXT UNIQUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Subscriptions table
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  plan TEXT NOT NULL CHECK (plan IN ('creator', 'pro', 'agency', 'studio')),
  monthly_allowance_seconds INT NOT NULL,
  rollover_seconds INT DEFAULT 0,
  used_seconds INT DEFAULT 0,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'past_due', 'canceled', 'paused')),
  stripe_subscription_id TEXT UNIQUE,
  auto_renew BOOLEAN DEFAULT true,
  start_date DATE NOT NULL,
  end_date DATE,
  next_billing_date DATE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Overage charges table
CREATE TABLE overage_charges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  extra_seconds FLOAT NOT NULL,
  rate_per_second NUMERIC(10,4) NOT NULL,
  total_cost NUMERIC(10,2) NOT NULL,
  stripe_invoice_id TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Pricing config table
CREATE TABLE pricing_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  model_tier TEXT NOT NULL,
  quality_tier TEXT NOT NULL,
  base_price_per_second NUMERIC(10,4) NOT NULL,
  multiplier FLOAT NOT NULL,
  valid_from TIMESTAMP DEFAULT NOW(),
  valid_until TIMESTAMP,
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(model_tier, quality_tier, valid_from)
);
```

**✅ Click "Run"** → You should see "Success. No rows returned"

---

### **Step 1.2: Create Balance Tracking Tables**
New Query → Paste this:

```sql
-- Token balances table
CREATE TABLE token_balances (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  available_seconds FLOAT DEFAULT 0 CHECK (available_seconds >= 0),
  lifetime_purchased_seconds FLOAT DEFAULT 0,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Balance transactions (audit trail)
CREATE TABLE balance_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  change_seconds FLOAT NOT NULL,
  new_balance FLOAT NOT NULL,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('purchase', 'generation', 'refund', 'subscription_reset', 'credit')),
  reference_id UUID,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Credits table (for refunds/promos)
CREATE TABLE credits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  amount_seconds FLOAT NOT NULL,
  reason TEXT NOT NULL CHECK (reason IN ('refund', 'compensation', 'promo', 'migration')),
  applied BOOLEAN DEFAULT false,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**✅ Click "Run"**

---

### **Step 1.3: Create Stripe Integration Tables**
New Query → Paste this:

```sql
-- Stripe events (prevent duplicate webhook processing)
CREATE TABLE stripe_events (
  event_id TEXT PRIMARY KEY,
  event_type TEXT NOT NULL,
  processed_at TIMESTAMP DEFAULT NOW(),
  payload JSONB
);

-- Failed payments tracking
CREATE TABLE failed_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  stripe_invoice_id TEXT,
  amount_due NUMERIC(10,2) NOT NULL,
  retry_count INT DEFAULT 0,
  next_retry_at TIMESTAMP,
  resolved BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- User preferences
CREATE TABLE user_preferences (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  allow_overages BOOLEAN DEFAULT false,
  overage_limit_usd NUMERIC(10,2) DEFAULT 100,
  email_notifications BOOLEAN DEFAULT true,
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**✅ Click "Run"**

---

### **Step 1.4: Add Indexes for Performance**
New Query → Paste this:

```sql
-- Indexes for fast queries
CREATE INDEX idx_video_generations_user_created ON video_generations(user_id, created_at DESC);
CREATE INDEX idx_video_generations_status ON video_generations(status);
CREATE INDEX idx_subscriptions_user_status ON subscriptions(user_id, status);
CREATE INDEX idx_subscriptions_stripe_id ON subscriptions(stripe_subscription_id);
CREATE INDEX idx_token_purchases_user ON token_purchases(user_id, created_at DESC);
CREATE INDEX idx_balance_transactions_user ON balance_transactions(user_id, created_at DESC);
CREATE INDEX idx_stripe_events_type ON stripe_events(event_type);
```

**✅ Click "Run"**

---

### **Step 1.5: Seed Pricing Data**
New Query → Paste this (adjust prices as needed):

```sql
-- Insert pricing tiers
INSERT INTO pricing_config (model_tier, quality_tier, base_price_per_second, multiplier) VALUES
-- Standard model
('standard', 'watermark', 0.01, 1.0),
('standard', 'standard', 0.015, 1.2),
('standard', 'hd', 0.02, 1.5),
-- Pro model
('pro', 'watermark', 0.02, 1.0),
('pro', 'standard', 0.03, 1.2),
('pro', 'hd', 0.04, 1.5),
('pro', 'ultra_hd', 0.06, 2.0),
-- Ultra model
('ultra', 'standard', 0.05, 1.0),
('ultra', 'hd', 0.07, 1.3),
('ultra', 'ultra_hd', 0.10, 1.8),
('ultra', 'studio', 0.15, 2.5);
```

**✅ Click "Run"**

---

## 🔐 **PHASE 2: Row Level Security (20 mins)**

### **Step 2.1: Enable RLS on All Tables**
New Query → Paste this:

```sql
-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_generations ENABLE ROW LEVEL SECURITY;
ALTER TABLE token_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE overage_charges ENABLE ROW LEVEL SECURITY;
ALTER TABLE token_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE balance_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE credits ENABLE ROW LEVEL SECURITY;
ALTER TABLE failed_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
-- Pricing config is public (read-only)
ALTER TABLE pricing_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe_events ENABLE ROW LEVEL SECURITY;
```

**✅ Click "Run"**

---

### **Step 2.2: Create RLS Policies**
New Query → Paste this:

```sql
-- Users can read their own data
CREATE POLICY "Users can view own profile" ON users FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can view own generations" ON video_generations FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own purchases" ON token_purchases FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own subscription" ON subscriptions FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own overages" ON overage_charges FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own balance" ON token_balances FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own transactions" ON balance_transactions FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own credits" ON credits FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own preferences" ON user_preferences FOR ALL USING (auth.uid() = user_id);

-- Pricing is public (read-only)
CREATE POLICY "Anyone can read pricing" ON pricing_config FOR SELECT TO authenticated, anon USING (true);

-- Stripe events are admin-only (handled by service role key)
CREATE POLICY "Service role only" ON stripe_events FOR ALL USING (false);
```

**✅ Click "Run"**

---

## ⚙️ **PHASE 3: Edge Functions (60 mins)**

### **Step 3.1: Setup Supabase CLI**
Open your terminal and paste:

```bash
# Install Supabase CLI (if not already installed)
npm install -g supabase

# Login
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF
```

**📝 Note:** Get `YOUR_PROJECT_REF` from Supabase Dashboard → Settings → API → Project URL (it's the random string)

---

### **Step 3.2: Create Edge Function Structure**
In terminal:

```bash
# Create functions
supabase functions new generate-video
supabase functions new purchase-tokens
supabase functions new subscribe-user
supabase functions new stripe-webhook
```

---

### **Step 3.3: Write generate-video Function**
Open `supabase/functions/generate-video/index.ts` and paste:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { user_id, duration_seconds, model_tier, quality_tier } = await req.json()

    // Validate input
    if (!user_id || !duration_seconds || !model_tier || !quality_tier) {
      return new Response(JSON.stringify({ error: 'Missing required fields' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    // Get pricing (use latest valid config)
    const { data: pricing, error: pricingError } = await supabase
      .from('pricing_config')
      .select('*')
      .eq('model_tier', model_tier)
      .eq('quality_tier', quality_tier)
      .lte('valid_from', new Date().toISOString())
      .or(`valid_until.is.null,valid_until.gte.${new Date().toISOString()}`)
      .order('valid_from', { ascending: false })
      .limit(1)
      .single()

    if (pricingError || !pricing) {
      return new Response(JSON.stringify({ error: 'Invalid pricing tier' }), { status: 400 })
    }

    const cost_usd = (pricing.base_price_per_second * pricing.multiplier * duration_seconds).toFixed(2)

    // Check balance (with row lock to prevent race conditions)
    const { data: balance, error: balanceError } = await supabase
      .rpc('get_user_balance_for_update', { p_user_id: user_id })

    if (balanceError) {
      return new Response(JSON.stringify({ error: 'Could not fetch balance' }), { status: 500 })
    }

    // Check if user has enough seconds
    if (balance.available_seconds < duration_seconds) {
      // Check subscription allowance
      const { data: sub } = await supabase
        .from('subscriptions')
        .select('*')
        .eq('user_id', user_id)
        .eq('status', 'active')
        .lte('start_date', new Date().toISOString())
        .or(`end_date.is.null,end_date.gte.${new Date().toISOString()}`)
        .single()

      const available_sub_seconds = sub 
        ? (sub.monthly_allowance_seconds + sub.rollover_seconds - sub.used_seconds)
        : 0

      if (balance.available_seconds + available_sub_seconds < duration_seconds) {
        // Check if overages allowed
        const { data: prefs } = await supabase
          .from('user_preferences')
          .select('allow_overages, overage_limit_usd')
          .eq('user_id', user_id)
          .single()

        if (!prefs?.allow_overages) {
          return new Response(JSON.stringify({ 
            error: 'Insufficient balance',
            available_seconds: balance.available_seconds + available_sub_seconds,
            required_seconds: duration_seconds
          }), { status: 402 })
        }

        // Calculate overage cost
        const overage_seconds = duration_seconds - (balance.available_seconds + available_sub_seconds)
        const overage_cost = (overage_seconds * pricing.base_price_per_second * pricing.multiplier * 1.5).toFixed(2) // 1.5x for overages

        if (parseFloat(overage_cost) > prefs.overage_limit_usd) {
          return new Response(JSON.stringify({ 
            error: 'Overage exceeds limit',
            overage_cost,
            limit: prefs.overage_limit_usd
          }), { status: 402 })
        }

        // Log overage charge
        await supabase.from('overage_charges').insert({
          user_id,
          extra_seconds: overage_seconds,
          rate_per_second: pricing.base_price_per_second * pricing.multiplier * 1.5,
          total_cost: overage_cost
        })
      }
    }

    // Create video generation record
    const { data: generation, error: genError } = await supabase
      .from('video_generations')
      .insert({
        user_id,
        duration_seconds,
        model_tier,
        quality_tier,
        multiplier: pricing.multiplier,
        cost_usd,
        status: 'pending'
      })
      .select()
      .single()

    if (genError) {
      return new Response(JSON.stringify({ error: 'Could not create generation' }), { status: 500 })
    }

    // Deduct balance (prioritize subscription, then tokens)
    await supabase.rpc('deduct_video_seconds', {
      p_user_id: user_id,
      p_duration: duration_seconds,
      p_reference_id: generation.id
    })

    return new Response(JSON.stringify({ 
      success: true,
      generation_id: generation.id,
      cost_usd
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})
```

---

### **Step 3.4: Create Database Functions (RPC)**
Go to Supabase → SQL Editor → New Query → Paste:

```sql
-- Function to get balance with row lock
CREATE OR REPLACE FUNCTION get_user_balance_for_update(p_user_id UUID)
RETURNS TABLE (available_seconds FLOAT) AS $$
BEGIN
  RETURN QUERY
  SELECT tb.available_seconds
  FROM token_balances tb
  WHERE tb.user_id = p_user_id
  FOR UPDATE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to deduct seconds
CREATE OR REPLACE FUNCTION deduct_video_seconds(
  p_user_id UUID,
  p_duration FLOAT,
  p_reference_id UUID
)
RETURNS VOID AS $$
DECLARE
  v_sub_available FLOAT;
  v_token_available FLOAT;
  v_sub_used FLOAT;
  v_token_used FLOAT;
  v_new_balance FLOAT;
BEGIN
  -- Start transaction
  BEGIN
    -- Check subscription first
    SELECT 
      GREATEST(0, monthly_allowance_seconds + rollover_seconds - used_seconds)
    INTO v_sub_available
    FROM subscriptions
    WHERE user_id = p_user_id 
      AND status = 'active'
      AND start_date <= CURRENT_DATE
      AND (end_date IS NULL OR end_date >= CURRENT_DATE)
    FOR UPDATE;

    v_sub_available := COALESCE(v_sub_available, 0);

    -- Get token balance
    SELECT available_seconds INTO v_token_available
    FROM token_balances
    WHERE user_id = p_user_id
    FOR UPDATE;

    v_token_available := COALESCE(v_token_available, 0);

    -- Deduct from subscription first
    IF v_sub_available >= p_duration THEN
      v_sub_used := p_duration;
      v_token_used := 0;
    ELSIF v_sub_available > 0 THEN
      v_sub_used := v_sub_available;
      v_token_used := p_duration - v_sub_available;
    ELSE
      v_sub_used := 0;
      v_token_used := p_duration;
    END IF;

    -- Update subscription used_seconds
    IF v_sub_used > 0 THEN
      UPDATE subscriptions
      SET used_seconds = used_seconds + v_sub_used
      WHERE user_id = p_user_id 
        AND status = 'active';
    END IF;

    -- Update token balance
    IF v_token_used > 0 THEN
      UPDATE token_balances
      SET 
        available_seconds = available_seconds - v_token_used,
        updated_at = NOW()
      WHERE user_id = p_user_id;

      SELECT available_seconds INTO v_new_balance
      FROM token_balances
      WHERE user_id = p_user_id;

      -- Log transaction
      INSERT INTO balance_transactions (
        user_id,
        change_seconds,
        new_balance,
        transaction_type,
        reference_id
      ) VALUES (
        p_user_id,
        -v_token_used,
        v_new_balance,
        'generation',
        p_reference_id
      );
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE;
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**✅ Click "Run"**

---

### **Step 3.5: Write purchase-tokens Function**
Open `supabase/functions/purchase-tokens/index.ts` and paste:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { user_id, bundle_size_seconds, price_usd, stripe_tx_id } = await req.json()

    if (!user_id || !bundle_size_seconds || !price_usd || !stripe_tx_id) {
      return new Response(JSON.stringify({ error: 'Missing required fields' }), {
        status: 400
      })
    }

    // Check if transaction already processed (idempotency)
    const { data: existing } = await supabase
      .from('token_purchases')
      .select('id')
      .eq('stripe_tx_id', stripe_tx_id)
      .single()

    if (existing) {
      return new Response(JSON.stringify({ 
        success: true,
        message: 'Already processed',
        purchase_id: existing.id
      }), { status: 200 })
    }

    // Insert purchase
    const { data: purchase, error: purchaseError } = await supabase
      .from('token_purchases')
      .insert({
        user_id,
        bundle_size_seconds,
        price_usd,
        stripe_tx_id
      })
      .select()
      .single()

    if (purchaseError) {
      return new Response(JSON.stringify({ error: 'Could not record purchase' }), {
        status: 500
      })
    }

    // Add tokens to balance
    const { data: balance } = await supabase
      .from('token_balances')
      .select('available_seconds')
      .eq('user_id', user_id)
      .single()

    const new_balance = (balance?.available_seconds || 0) + bundle_size_seconds

    if (balance) {
      // Update existing
      await supabase
        .from('token_balances')
        .update({
          available_seconds: new_balance,
          lifetime_purchased_seconds: supabase.rpc('increment', { x: bundle_size_seconds }),
          updated_at: new Date().toISOString()
        })
        .eq('user_id', user_id)
    } else {
      // Create new
      await supabase
        .from('token_balances')
        .insert({
          user_id,
          available_seconds: bundle_size_seconds,
          lifetime_purchased_seconds: bundle_size_seconds
        })
    }

    // Log transaction
    await supabase
      .from('balance_transactions')
      .insert({
        user_id,
        change_seconds: bundle_size_seconds,
        new_balance,
        transaction_type: 'purchase',
        reference_id: purchase.id
      })

    return new Response(JSON.stringify({ 
      success: true,
      purchase_id: purchase.id,
      new_balance
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500
    })
  }
})
```

---

### **Step 3.6: Write subscribe-user Function**
Open `supabase/functions/subscribe-user/index.ts` and paste:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { user_id, plan, stripe_subscription_id } = await req.json()

    // Define plan allowances
    const plans = {
      'creator': 1800,    // 30 minutes
      'pro': 7200,        // 2 hours
      'agency': 18000,    // 5 hours
      'studio': 36000     // 10 hours
    }

    const monthly_allowance = plans[plan]
    if (!monthly_allowance) {
      return new Response(JSON.stringify({ error: 'Invalid plan' }), { status: 400 })
    }

    // Check for existing active subscription
    const { data: existing } = await supabase
      .from('subscriptions')
      .select('*')
      .eq('user_id', user_id)
      .eq('status', 'active')
      .single()

    if (existing) {
      // Handle upgrade/downgrade
      const rollover = Math.max(0, existing.monthly_allowance_seconds + existing.rollover_seconds - existing.used_seconds)
      
      // Cancel old subscription
      await supabase
        .from('subscriptions')
        .update({ status: 'canceled', end_date: new Date().toISOString() })
        .eq('id', existing.id)
      
      // Create new with rollover
      const { data: newSub, error } = await supabase
        .from('subscriptions')
        .insert({
          user_id,
          plan,
          monthly_allowance_seconds: monthly_allowance,
          rollover_seconds: Math.min(rollover, monthly_allowance), // Cap at monthly allowance
          used_seconds: 0,
          status: 'active',
          stripe_subscription_id,
          start_date: new Date().toISOString(),
          next_billing_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
        })
        .select()
        .single()

      return new Response(JSON.stringify({ success: true, subscription: newSub }), {
        status: 200
      })
    }

    // Create new subscription
    const { data: newSub, error } = await supabase
      .from('subscriptions')
      .insert({
        user_id,
        plan,
        monthly_allowance_seconds: monthly_allowance,
        rollover_seconds: 0,
        used_seconds: 0,
        status: 'active',
        stripe_subscription_id,
        start_date: new Date().toISOString(),
        next_billing_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
      })
      .select()
      .single()

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), { status: 500 })
    }

    // Update user table
    await supabase
      .from('users')
      .update({ subscription_plan: plan })
      .eq('id', user_id)

    return new Response(JSON.stringify({ success: true, subscription: newSub }), {
      status: 200
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})
```

---

### **Step 3.7: Write stripe-webhook Function**
Open `supabase/functions/stripe-webhook/index.ts` and paste:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@14.21.0'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
  apiVersion: '2023-10-16',
})

serve(async (req) => {
  const signature = req.headers.get('stripe-signature')
  const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')

  if (!signature || !webhookSecret) {
    return new Response('Missing signature or secret', { status: 400 })
  }

  try {
    const body = await req.text()
    const event = stripe.webhooks.constructEvent(body, signature, webhookSecret)

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Check if already processed
    const { data: existing } = await supabase
      .from('stripe_events')
      .select('event_id')
      .eq('event_id', event.id)
      .single()

    if (existing) {
      return new Response(JSON.stringify({ received: true, processed: false, reason: 'duplicate' }), {
        status: 200
      })
    }

    // Log event
    await supabase
      .from('stripe_events')
      .insert({
        event_id: event.id,
        event_type: event.type,
        payload: event.data.object
      })

    // Handle event types
    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object as Stripe.Checkout.Session
        
        if (session.mode === 'subscription') {
          // Subscription purchase
          const user_id = session.metadata?.user_id
          const plan = session.metadata?.plan
          
          if (user_id && plan) {
            await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/subscribe-user`, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${Deno.env.get('SUPABASE_ANON_KEY')}`
              },
              body: JSON.stringify({
                user_id,
                plan,
                stripe_subscription_id: session.subscription
              })
            })
          }
        } else if (session.mode === 'payment') {
          // Token purchase
          const user_id = session.metadata?.user_id
          const bundle_size_seconds = parseInt(session.metadata?.bundle_size_seconds || '0')
          
          if (user_id && bundle_size_seconds) {
            await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/purchase-tokens`, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${Deno.env.get('SUPABASE_ANON_KEY')}`
              },
              body: JSON.stringify({
                user_id,
                bundle_size_seconds,
                price_usd: (session.amount_total || 0) / 100,
                stripe_tx_id: session.payment_intent
              })
            })
          }
        }
        break
      }

      case 'customer.subscription.updated': {
        const subscription = event.data.object as Stripe.Subscription
        const user_id = subscription.metadata?.user_id
        
        if (user_id) {
          await supabase
            .from('subscriptions')
            .update({
              status: subscription.status === 'active' ? 'active' : 'paused',
              next_billing_date: new Date(subscription.current_period_end * 1000).toISOString()
            })
            .eq('stripe_subscription_id', subscription.id)
        }
        break
      }

      case 'customer.subscription.deleted': {
        const subscription = event.data.object as Stripe.Subscription
        
        await supabase
          .from('subscriptions')
          .update({
            status: 'canceled',
            end_date: new Date().toISOString()
          })
          .eq('stripe_subscription_id', subscription.id)
        break
      }

      case 'invoice.payment_failed': {
        const invoice = event.data.object as Stripe.Invoice
        const user_id = invoice.metadata?.user_id
        
        if (user_id) {
          await supabase
            .from('failed_payments')
            .insert({
              user_id,
              stripe_invoice_id: invoice.id,
              amount_due: (invoice.amount_due || 0) / 100,
              retry_count: invoice.attempt_count,
              next_retry_at: invoice.next_payment_attempt 
                ? new Date(invoice.next_payment_attempt * 1000).toISOString()
                : null
            })

          // Mark subscription as past_due
          if (invoice.subscription) {
            await supabase
              .from('subscriptions')
              .update({ status: 'past_due' })
              .eq('stripe_subscription_id', invoice.subscription)
          }
        }
        break
      }

      case 'invoice.paid': {
        const invoice = event.data.object as Stripe.Invoice
        
        // Mark failed payment as resolved
        if (invoice.subscription) {
          await supabase
            .from('failed_payments')
            .update({ resolved: true })
            .eq('stripe_invoice_id', invoice.id)

          // Reactivate subscription
          await supabase
            .from('subscriptions')
            .update({ status: 'active' })
            .eq('stripe_subscription_id', invoice.subscription)
        }
        break
      }
    }

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('Webhook error:', error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400
    })
  }
})
```

---

### **Step 3.8: Deploy Edge Functions**
In terminal:

```bash
# Set secrets
supabase secrets set STRIPE_SECRET_KEY=sk_test_... # Your Stripe secret key
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_... # Get from Stripe dashboard

# Deploy functions
supabase functions deploy generate-video
supabase functions deploy purchase-tokens
supabase functions deploy subscribe-user
supabase functions deploy stripe-webhook
```

**✅ You should see "Deployed successfully"**

---

## 💳 **PHASE 4: Stripe Integration (30 mins)**

### **Step 4.1: Create Stripe Products**
1. Go to https://dashboard.stripe.com/test/products
2. Click "Add product"
3. Create these products:

**Subscriptions:**
- Name: "Creator Plan", Price: $29/month, Recurring
- Name: "Pro Plan", Price: $79/month, Recurring
- Name: "Agency Plan", Price: $199/month, Recurring
- Name: "Studio Plan", Price: $399/month, Recurring

**Token Bundles:**
- Name: "30 Min Bundle", Price: $19, One-time
- Name: "2 Hour Bundle", Price: $59, One-time
- Name: "5 Hour Bundle", Price: $129, One-time

**✅ Save the Price IDs** (they look like `price_ABC...`)

---

### **Step 4.2: Setup Webhook in Stripe**
1. Go to https://dashboard.stripe.com/test/webhooks
2. Click "Add endpoint"
3. Endpoint URL: `https://YOUR_PROJECT_REF.supabase.co/functions/v1/stripe-webhook`
4. Events to send:
   - `checkout.session.completed`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_failed`
   - `invoice.paid`
5. Click "Add endpoint"
6. **Copy the Signing Secret** (`whsec_...`)

---

### **Step 4.3: Update Stripe Webhook Secret**
In terminal:

```bash
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_YOUR_SECRET_HERE
```

---

## 🎨 **PHASE 5: Frontend Integration (45 mins)**

### **Step 5.1: Install Dependencies**
In your project folder:

```bash
npm install @stripe/stripe-js
```

---

### **Step 5.2: Create Stripe Checkout Component**
Create `components/PricingPlans.tsx`:

```typescript
'use client'

import { loadStripe } from '@stripe/stripe-js'
import { useState } from 'react'
import { createClient } from '@/utils/supabase/client'

const stripePromise = loadStripe(process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY!)

export default function PricingPlans() {
  const [loading, setLoading] = useState<string | null>(null)
  const supabase = createClient()

  const handleSubscribe = async (plan: string, priceId: string) => {
    setLoading(plan)
    
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      alert('Please sign in first')
      setLoading(null)
      return
    }

    const response = await fetch('/api/create-checkout-session', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        priceId,
        mode: 'subscription',
        userId: user.id,
        plan
      })
    })

    const { sessionId } = await response.json()
    const stripe = await stripePromise
    await stripe?.redirectToCheckout({ sessionId })
  }

  const handlePurchaseTokens = async (bundleSeconds: number, priceId: string) => {
    setLoading(priceId)
    
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      alert('Please sign in first')
      setLoading(null)
      return
    }

    const response = await fetch('/api/create-checkout-session', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        priceId,
        mode: 'payment',
        userId: user.id,
        bundleSeconds
      })
    })

    const { sessionId } = await response.json()
    const stripe = await stripePromise
    await stripe?.redirectToCheckout({ sessionId })
  }

  return (
    <div className="grid md:grid-cols-2 gap-8 p-8">
      {/* Subscriptions */}
      <div>
        <h2 className="text-2xl font-bold mb-4">Monthly Plans</h2>
        <div className="space-y-4">
          <div className="border rounded p-4">
            <h3 className="font-bold">Creator - $29/mo</h3>
            <p className="text-sm text-gray-600">30 minutes/month</p>
            <button
              onClick={() => handleSubscribe('creator', 'price_YOUR_CREATOR_PRICE_ID')}
              disabled={loading === 'creator'}
              className="mt-2 bg-blue-500 text-white px-4 py-2 rounded"
            >
              {loading === 'creator' ? 'Loading...' : 'Subscribe'}
            </button>
          </div>

          <div className="border rounded p-4">
            <h3 className="font-bold">Pro - $79/mo</h3>
            <p className="text-sm text-gray-600">2 hours/month</p>
            <button
              onClick={() => handleSubscribe('pro', 'price_YOUR_PRO_PRICE_ID')}
              disabled={loading === 'pro'}
              className="mt-2 bg-blue-500 text-white px-4 py-2 rounded"
            >
              {loading === 'pro' ? 'Loading...' : 'Subscribe'}
            </button>
          </div>
        </div>
      </div>

      {/* Token Bundles */}
      <div>
        <h2 className="text-2xl font-bold mb-4">Token Bundles</h2>
        <div className="space-y-4">
          <div className="border rounded p-4">
            <h3 className="font-bold">30 Minutes - $19</h3>
            <button
              onClick={() => handlePurchaseTokens(1800, 'price_YOUR_30MIN_PRICE_ID')}
              disabled={loading === 'price_YOUR_30MIN_PRICE_ID'}
              className="mt-2 bg-green-500 text-white px-4 py-2 rounded"
            >
              {loading === 'price_YOUR_30MIN_PRICE_ID' ? 'Loading...' : 'Buy Now'}
            </button>
          </div>

          <div className="border rounded p-4">
            <h3 className="font-bold">2 Hours - $59</h3>
            <button
              onClick={() => handlePurchaseTokens(7200, 'price_YOUR_2HR_PRICE_ID')}
              disabled={loading === 'price_YOUR_2HR_PRICE_ID'}
              className="mt-2 bg-green-500 text-white px-4 py-2 rounded"
            >
              {loading === 'price_YOUR_2HR_PRICE_ID' ? 'Loading...' : 'Buy Now'}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
```

**📝 Replace `price_YOUR_..._PRICE_ID` with your actual Stripe Price IDs from Step 4.1**

---

### **Step 5.3: Create API Route for Checkout**
Create `app/api/create-checkout-session/route.ts`:

```typescript
import { NextResponse } from 'next/server'
import Stripe from 'stripe'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2023-10-16'
})

export async function POST(req: Request) {
  try {
    const { priceId, mode, userId, plan, bundleSeconds } = await req.json()

    const session = await stripe.checkout.sessions.create({
      mode: mode as 'subscription' | 'payment',
      line_items: [
        {
          price: priceId,
          quantity: 1
        }
      ],
      success_url: `${req.headers.get('origin')}/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${req.headers.get('origin')}/pricing`,
      metadata: {
        user_id: userId,
        ...(plan && { plan }),
        ...(bundleSeconds && { bundle_size_seconds: bundleSeconds.toString() })
      }
    })

    return NextResponse.json({ sessionId: session.id })
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 })
  }
}
```

---

### **Step 5.4: Create Balance Display Component**
Create `components/UserBalance.tsx`:

```typescript
'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/utils/supabase/client'

export default function UserBalance() {
  const [balance, setBalance] = useState<any>(null)
  const [subscription, setSubscription] = useState<any>(null)
  const supabase = createClient()

  useEffect(() => {
    async function fetchBalance() {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) return

      // Get token balance
      const { data: tokenData } = await supabase
        .from('token_balances')
        .select('*')
        .eq('user_id', user.id)
        .single()

      // Get active subscription
      const { data: subData } = await supabase
        .from('subscriptions')
        .select('*')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .single()

      setBalance(tokenData)
      setSubscription(subData)
    }

    fetchBalance()
  }, [])

  const formatSeconds = (seconds: number) => {
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)
    return `${hours}h ${minutes}m`
  }

  const subAvailable = subscription 
    ? subscription.monthly_allowance_seconds + subscription.rollover_seconds - subscription.used_seconds
    : 0

  return (
    <div className="bg-white shadow rounded-lg p-6">
      <h2 className="text-xl font-bold mb-4">Your Balance</h2>
      
      {subscription && (
        <div className="mb-4 p-4 bg-blue-50 rounded">
          <p className="font-semibold">Active Plan: {subscription.plan}</p>
          <p className="text-sm">Available: {formatSeconds(subAvailable)}</p>
          <p className="text-xs text-gray-600">
            Next billing: {new Date(subscription.next_billing_date).toLocaleDateString()}
          </p>
        </div>
      )}

      <div className="p-4 bg-green-50 rounded">
        <p className="font-semibold">Token Balance</p>
        <p className="text-2xl">{formatSeconds(balance?.available_seconds || 0)}</p>
      </div>
    </div>
  )
}
```

---

### **Step 5.5: Create Video Generation Component**
Create `components/GenerateVideo.tsx`:

```typescript
'use client'

import { useState } from 'react'
import { createClient } from '@/utils/supabase/client'

export default function GenerateVideo() {
  const [duration, setDuration] = useState(30)
  const [modelTier, setModelTier] = useState('standard')
  const [qualityTier, setQualityTier] = useState('standard')
  const [loading, setLoading] = useState(false)
  const supabase = createClient()

  const handleGenerate = async () => {
    setLoading(true)
    
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      alert('Please sign in')
      setLoading(false)
      return
    }

    const response = await supabase.functions.invoke('generate-video', {
      body: {
        user_id: user.id,
        duration_seconds: duration,
        model_tier: modelTier,
        quality_tier: qualityTier
      }
    })

    if (response.error) {
      alert(response.error.message || 'Generation failed')
    } else {
      alert(`Video generation started! Cost: $${response.data.cost_usd}`)
    }

    setLoading(false)
  }

  return (
    <div className="bg-white shadow rounded-lg p-6">
      <h2 className="text-xl font-bold mb-4">Generate Video</h2>
      
      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium mb-1">Duration (seconds)</label>
          <input
            type="number"
            value={duration}
            onChange={(e) => setDuration(parseInt(e.target.value))}
            className="border rounded px-3 py-2 w-full"
            min="5"
            max="300"
          />
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">Model Tier</label>
          <select
            value={modelTier}
            onChange={(e) => setModelTier(e.target.value)}
            className="border rounded px-3 py-2 w-full"
          >
            <option value="standard">Standard</option>
            <option value="pro">Pro</option>
            <option value="ultra">Ultra</option>
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">Quality Tier</label>
          <select
            value={qualityTier}
            onChange={(e) => setQualityTier(e.target.value)}
            className="border rounded px-3 py-2 w-full"
          >
            <option value="watermark">Watermark (Cheapest)</option>
            <option value="standard">Standard</option>
            <option value="hd">HD</option>
            <option value="ultra_hd">Ultra HD</option>
            <option value="studio">Studio</option>
          </select>
        </div>

        <button
          onClick={handleGenerate}
          disabled={loading}
          className="w-full bg-blue-500 text-white px-4 py-2 rounded font-medium hover:bg-blue-600 disabled:opacity-50"
        >
          {loading ? 'Generating...' : 'Generate Video'}
        </button>
      </div>
    </div>
  )
}
```

---

## ✅ **PHASE 6: Testing (20 mins)**

### **Step 6.1: Test Token Purchase**
1. Go to your app's pricing page
2. Click "Buy 30 Minutes"
3. Use Stripe test card: `4242 4242 4242 4242`
4. Check Supabase → Table Editor → `token_balances` (should see credits added)

---

### **Step 6.2: Test Subscription**
1. Click "Subscribe to Creator"
2. Complete checkout
3. Check `subscriptions` table (status should be 'active')

---

### **Step 6.3: Test Video Generation**
1. Go to generate video page
2. Set duration to 30 seconds
3. Click generate
4. Check `video_generations` table (should see new row)
5. Check `token_balances` (should be deducted)

---

### **Step 6.4: Test Webhook**
In Stripe Dashboard:
1. Go to Webhooks → Your endpoint
2. Click "Send test webhook"
3. Select `checkout.session.completed`
4. Check Supabase `stripe_events` table (should see the event)

---

## 🎉 **You're Done!**

### **What You Built:**
✅ Full database schema with RLS
✅ Token balance system
✅ Subscription management
✅ Video generation with cost calculation
✅ Stripe integration
✅ Webhook handling
✅ Frontend components

### **Next Steps:**
1. Add email notifications (use Supabase Edge Functions + Resend)
2. Build analytics dashboard
3. Add refund handling
4. Implement usage charts
5. Set up automated subscription renewals

---

## 🆘 **Common Issues & Fixes**

**Problem:** Edge function returns 401
- **Fix:** Check if `SUPABASE_SERVICE_ROLE_KEY` is set correctly

**Problem:** Webhook not working
- **Fix:** Verify `STRIPE_WEBHOOK_SECRET` matches Stripe dashboard

**Problem:** RLS blocking queries
- **Fix:** Use service role key for Edge Functions, not anon key

**Problem:** Balance not updating
- **Fix:** Check `balance_transactions` table for errors

---

Need help with any specific step? Let me know which phase you're on! 🚀


# 🔌 **Backend System Connections**

Your monetization backend connects to **3 external systems**:

---

## 1️⃣ **Supabase (Your Primary Backend)**

### **What it provides:**
- **PostgreSQL Database** - All your tables live here
- **Edge Functions** - Serverless functions for business logic
- **Authentication** - User management (via `auth.uid()`)
- **Row Level Security (RLS)** - Data access control
- **Realtime subscriptions** (optional) - Live data updates

### **Connection points:**
```typescript
// In your frontend
import { createClient } from '@supabase/supabase-js'
const supabase = createClient(
  'https://YOUR_PROJECT.supabase.co',
  'YOUR_ANON_KEY' // For client-side
)

// In Edge Functions
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY // Full access
)
```

### **What flows through it:**
- User balance queries
- Video generation requests
- Subscription status checks
- Transaction logs
- Analytics queries

---

## 2️⃣ **Stripe (Payment Processing)**

### **What it provides:**
- **Payment processing** - Credit card charges
- **Subscription billing** - Recurring payments
- **Customer management** - Stripe customer IDs
- **Webhooks** - Real-time payment events
- **Checkout sessions** - Hosted payment pages

### **Connection points:**

**Frontend → Stripe:**
```typescript
import { loadStripe } from '@stripe/stripe-js'
const stripe = await loadStripe('pk_test_...')
await stripe.redirectToCheckout({ sessionId })
```

**Backend → Stripe:**
```typescript
// In your API routes
import Stripe from 'stripe'
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY)

// Create checkout session
const session = await stripe.checkout.sessions.create({...})
```

**Stripe → Your Webhook:**
```
POST https://YOUR_PROJECT.supabase.co/functions/v1/stripe-webhook
Headers: stripe-signature
Body: Event payload
```

### **What flows through it:**
- Token purchases (`checkout.session.completed`)
- Subscription activations (`customer.subscription.created`)
- Failed payments (`invoice.payment_failed`)
- Subscription updates (`customer.subscription.updated`)
- Cancellations (`customer.subscription.deleted`)

### **Key data synced:**
| Stripe Field | Your DB Field |
|--------------|---------------|
| `customer.id` | `users.stripe_customer_id` |
| `subscription.id` | `subscriptions.stripe_subscription_id` |
| `payment_intent.id` | `token_purchases.stripe_tx_id` |
| `invoice.id` | `overage_charges.stripe_invoice_id` |

---

## 3️⃣ **Your Video Generation AI Service** *(Not Yet Connected)*

### **What it needs to provide:**
- Video generation API endpoint
- Processing status updates
- Video output URLs

### **How it will connect:**
```typescript
// After video generation request is approved in DB
const response = await fetch('https://your-ai-service.com/generate', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer YOUR_AI_API_KEY',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    duration: 30,
    model: 'pro',
    quality: 'hd',
    callback_url: 'https://YOUR_PROJECT.supabase.co/functions/v1/video-callback'
  })
})

// AI service calls back when done
// POST /functions/v1/video-callback
{
  generation_id: 'uuid',
  status: 'success',
  video_url: 'https://...',
  actual_duration: 29.5
}
```

### **You'll need to:**
1. Create `video-callback` Edge Function
2. Update `video_generations` status to 'success'/'failed'
3. Add `video_url` column to `video_generations` table
4. Handle actual vs. estimated duration differences

---

## 📊 **System Integration Flow Diagram**

```
┌─────────────┐
│   USER      │
│  (Browser)  │
└──────┬──────┘
       │
       ├─────────────────────────────────┐
       │                                 │
       ▼                                 ▼
┌─────────────┐                   ┌─────────────┐
│  Supabase   │◄─────────────────►│   Stripe    │
│   Client    │   create checkout │  Checkout   │
│     SDK     │                   │   Session   │
└──────┬──────┘                   └──────┬──────┘
       │                                 │
       │ invoke function                 │ webhook
       ▼                                 ▼
┌─────────────────────────────────────────────┐
│          Supabase Edge Functions            │
│  ┌────────────┐  ┌────────────┐            │
│  │ generate-  │  │  stripe-   │            │
│  │   video    │  │  webhook   │            │
│  └─────┬──────┘  └─────┬──────┘            │
│        │               │                    │
│        │  write        │  write             │
│        ▼               ▼                    │
│  ┌─────────────────────────────┐           │
│  │   PostgreSQL Database       │           │
│  │  • video_generations        │           │
│  │  • token_balances           │           │
│  │  • subscriptions            │           │
│  │  • stripe_events            │           │
│  └─────────────────────────────┘           │
└─────────────────────────────────────────────┘
       │
       │ call AI API
       ▼
┌─────────────┐
│  AI Video   │
│  Generator  │
│  (Future)   │
└─────────────┘
```

---

## 🔐 **API Keys & Secrets You Need**

### **Supabase (2 keys):**
```bash
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJhbG...        # Public, client-side
SUPABASE_SERVICE_ROLE_KEY=eyJhbG... # Secret, server-side only
```

### **Stripe (3 keys):**
```bash
# Frontend
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...

# Backend
STRIPE_SECRET_KEY=sk_test_...       # Server-side only
STRIPE_WEBHOOK_SECRET=whsec_...     # For webhook verification
```

### **AI Service (future):**
```bash
AI_SERVICE_API_KEY=xxx
AI_SERVICE_ENDPOINT=https://...
```

---

## 🌐 **External Network Calls**

### **From your frontend:**
1. `https://YOUR_PROJECT.supabase.co` - Database queries
2. `https://checkout.stripe.com` - Payment redirects
3. `https://js.stripe.com` - Stripe.js library

### **From Supabase Edge Functions:**
1. `https://api.stripe.com` - Stripe API calls
2. `https://YOUR-AI-SERVICE.com` (future) - Video generation

### **To your backend (webhooks):**
1. Stripe → `https://YOUR_PROJECT.supabase.co/functions/v1/stripe-webhook`
2. AI Service (future) → `https://YOUR_PROJECT.supabase.co/functions/v1/video-callback`

---

## 🚨 **Important Security Notes**

### **Never expose these in frontend:**
- `SUPABASE_SERVICE_ROLE_KEY`
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`

### **These are safe for frontend:**
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY`

### **Webhook security:**
Always verify webhook signatures:
```typescript
// Stripe webhooks
const event = stripe.webhooks.constructEvent(
  body,
  signature,
  STRIPE_WEBHOOK_SECRET
)
```

---

## 📋 **Summary**

**Current Connections (2):**
1. ✅ **Supabase** - Database + Edge Functions
2. ✅ **Stripe** - Payments + Subscriptions

**Future Connections (1):**
3. ⏳ **AI Video Service** - Actual video generation

**Total external API calls per video generation:**
- Frontend → Supabase: 1 call
- Supabase → Database: 3-5 queries
- Supabase → AI Service: 1 call (future)
- AI Service → Supabase callback: 1 call (future)

No other systems needed! This is a clean, minimal architecture. 🎯
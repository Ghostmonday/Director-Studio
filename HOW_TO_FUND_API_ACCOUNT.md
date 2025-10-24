# 🚨 EMERGENCY API TOP-UP SYSTEM

## Problem
Users pay → You get money → But Pollo API isn't funded automatically!

## Quick Solution (Launch Tonight)

### 1. Set Daily Budget Alert
```
Pollo Dashboard → Settings → Billing
- Set daily limit: $50
- Enable email alerts at 80%
- Auto-pause at limit ✓
```

### 2. Manual Top-Up Process
```
Every morning:
1. Check yesterday's App Store sales
2. Top up Pollo with 70% of revenue
3. Keep 30% for Apple's cut + profit
```

### 3. Monitor Usage Formula
```
Daily API Budget = Yesterday's Revenue × 0.7

Example:
- 100 users buy $4.99 = $499
- Apple takes 30% = $349 (you get)
- Top up Pollo with $244 (70%)
- Keep $105 for operations
```

## Automated Solution (Week 2)

### Webhook Flow
```
1. StoreKit Purchase → Your Server
2. Log purchase in database
3. Daily cron job:
   - Sum purchases
   - API call to Pollo billing
   - Auto top-up account
```

### Simple Node.js Webhook
```javascript
// webhook.js
app.post('/purchase', async (req, res) => {
  const { userId, amount, credits } = req.body;
  
  // Log to database
  await db.purchases.create({
    userId,
    amount,
    credits,
    date: new Date()
  });
  
  // Check if we need to top up
  const todayRevenue = await db.getTodayRevenue();
  if (todayRevenue > 100) {
    // Top up Pollo account
    await polloAPI.addCredits(todayRevenue * 0.7);
  }
  
  res.json({ success: true });
});
```

## Emergency Measures

### If API Runs Out
1. **Immediate**: Add $100 manual top-up
2. **User sees**: "High demand - try again in 1 hour"
3. **You do**: Check sales, top up more

### Rate Limiting
```swift
// In PipelineServiceBridge.swift
let maxDailyGenerations = 500
let todayCount = UserDefaults.standard.integer(forKey: "generations_\(todayString)")

if todayCount > maxDailyGenerations {
    throw PipelineError.configurationError("Service at capacity. Please try again later.")
}
```

## Launch Week Monitoring

### Daily Checklist
- [ ] Check App Store Connect sales
- [ ] Check Pollo API usage
- [ ] Top up Pollo account
- [ ] Monitor user complaints
- [ ] Adjust limits if needed

### Key Metrics
- Revenue per day: $____
- API cost per day: $____
- Margin: ____%
- User complaints: ____

## Cost Control

### Per-User Limits
```swift
// Add to CreditsManager
func canGenerateToday() -> Bool {
    let key = "daily_\(userId)_\(todayString)"
    let count = UserDefaults.standard.integer(forKey: key)
    return count < 10 // Max 10 per day per user
}
```

### Smart Pricing
- 1 credit = 5 seconds = ~$0.25 API cost
- Sell for $0.50/credit = 100% markup
- Covers Apple's cut + profit

## Emergency Contacts

- Pollo API Support: support@pollo.ai
- Billing issues: billing@pollo.ai
- Rate limit increases: enterprise@pollo.ai

## Launch Day Script

```bash
# Morning routine
1. Check overnight sales: $XXX
2. Calculate top-up: $XXX × 0.7 = $XXX
3. Add to Pollo account
4. Set daily limit to match
5. Monitor every 2 hours
```

Remember: It's better to pause service temporarily than to lose money on every generation!

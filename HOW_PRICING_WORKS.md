# 💰 DirectorStudio Pricing & Metering System

## 📊 Credit-Based Pricing Model

### Base Video Cost
- **1 credit per 5 seconds of video**
- Examples:
  - 5-second video = 1 credit
  - 10-second video = 2 credits
  - 15-second video = 3 credits
  - 20-second video = 4 credits

### Pipeline Stage Costs
Each AI enhancement stage adds to the total cost:

| Pipeline Stage | Credit Cost | Description |
|----------------|-------------|-------------|
| Continuity Analysis | +1 credit | Analyzes scene consistency |
| Continuity Injection | +1 credit | Maintains visual continuity |
| AI Enhancement | +2 credits | DeepSeek prompt enhancement (premium) |
| Camera Direction | +1 credit | Adds cinematic camera movements |
| Lighting | +1 credit | Enhances lighting and atmosphere |

### Example Calculations

**Basic Video (10 seconds, no enhancements):**
- Base: 2 credits
- Total: 2 credits

**Enhanced Video (10 seconds, with enhancement + lighting):**
- Base: 2 credits
- AI Enhancement: +2 credits
- Lighting: +1 credit
- Total: 5 credits

**Full Pipeline (20 seconds, all features):**
- Base: 4 credits
- Continuity Analysis: +1 credit
- Continuity Injection: +1 credit
- AI Enhancement: +2 credits
- Camera Direction: +1 credit
- Lighting: +1 credit
- Total: 10 credits

## 🔍 Pipeline Metering Details

### 1. **Pre-Generation Estimation**
- Shows exact cost before generation
- "See breakdown" button for transparency
- Updates live as options change

### 2. **Credit Check**
- Validates sufficient credits before API calls
- Shows specific error if insufficient
- Prevents partial generation

### 3. **Usage Tracking**
```
💰 Cost Breakdown:
• Video (10s): 2 credits
• AI Enhancement: 2 credits
• Lighting: 1 credit
━━━━━━━━━━━━━━━
Total: 5 credits
```

### 4. **Demo Mode Trigger**
- When credits = 0, automatically uses demo mode
- No API calls = no costs
- Users can still test all features

## 💡 Monetization Strategy

### Free Tier
- 3 credits on signup (1-3 basic videos)
- Enough to experience the app
- Encourages quick purchase decision

### Credit Packages
- **Starter**: 10 credits ($4.99) = $0.50/credit
- **Popular**: 30 credits ($9.99) = $0.33/credit (34% savings)
- **Professional**: 100 credits ($24.99) = $0.25/credit (50% savings)

### User Value Proposition
- Pay only for what you use
- No subscriptions
- Credits never expire
- Transparent pricing

## 📈 Pipeline Cost Optimization Tips

### For Users:
1. **Test with short videos first** (5 seconds = 1 credit)
2. **Use basic generation** for rough drafts
3. **Enable enhancement only for final versions**
4. **Batch similar videos** to reuse continuity

### For Developers:
1. **Monitor API costs** per pipeline stage
2. **Adjust credit pricing** based on actual costs
3. **Consider caching** for similar prompts
4. **Add bulk discounts** for heavy users

## 🛠️ Technical Implementation

### Credit Calculation Formula
```swift
creditsNeeded = ceil(duration / 5.0) + pipelineStages.sum()
```

### Pipeline Stage Flags
- Each stage is independently toggleable
- Costs update in real-time
- Clear visual feedback

### Error Handling
- Specific "insufficient credits" errors
- Automatic demo mode fallback
- Purchase prompt when needed

## 📊 Analytics to Track

1. **Conversion Metrics**
   - Free → Paid conversion rate
   - Average time to first purchase
   - Most popular package

2. **Usage Patterns**
   - Average credits per video
   - Most used pipeline stages
   - Video duration distribution

3. **Revenue Metrics**
   - ARPU (Average Revenue Per User)
   - Credit consumption rate
   - Package upgrade patterns

## 🔮 Future Enhancements

1. **Dynamic Pricing**
   - Time-based discounts
   - Bulk generation savings
   - Loyalty rewards

2. **Advanced Features**
   - Priority processing queue
   - HD/4K options (premium credits)
   - Custom AI models

3. **Enterprise Options**
   - Unlimited plans
   - API access
   - White-label solutions

---

This pricing model ensures:
- ✅ Predictable costs for users
- ✅ Sustainable revenue for developers
- ✅ Fair pay-per-use system
- ✅ Clear value proposition

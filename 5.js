// video-generator.js - Complete Implementation Template
// Copy this file and add your API key

const POLLO_API_KEY = process.env.POLLO_API_KEY; // Get from pollo.ai dashboard

// ============================================
// TIER CONFIGURATION WITH 210% MARKUP
// ============================================

const PRICING_TIERS = {
  economy: {
    name: 'Economy',
    model: 'Kling 1.6',
    endpoint: 'https://pollo.ai/api/platform/generation/kling-ai/kling-v1-6',
    baseCost: 0.07,      // What Pollo charges you
    customerPrice: 0.20,  // What you charge customer
    profit: 0.13,         // Your profit per second
    maxDuration: 10,
    features: ['Budget-friendly', 'Lifelike movements', 'Text/Image input']
  },
  basic: {
    name: 'Basic',
    model: 'Pollo 1.6',
    endpoint: 'https://pollo.ai/api/platform/generation/pollo/pollo-v1-6',
    baseCost: 0.10,      // What Pollo charges you
    customerPrice: 0.31,  // What you charge customer (3.1x markup)
    profit: 0.21,         // Your profit per second
    maxDuration: 8,
    features: ['Fast', 'Good quality', 'Text/Image input']
  },
  pro: {
    name: 'Pro',
    model: 'Kling 2.5 Turbo',
    endpoint: 'https://pollo.ai/api/platform/generation/kling-ai/kling-v2-5-turbo',
    baseCost: 0.12,
    customerPrice: 0.37,
    profit: 0.25,
    maxDuration: 10,
    features: ['Director-level', 'Pro camera', 'Enhanced motion']
  },
  premium: {
    name: 'Premium',
    model: 'Runway Gen-4 Turbo',
    endpoint: 'https://pollo.ai/api/platform/generation/runway/runway-gen-4-turbo',
    baseCost: 0.30,
    customerPrice: 0.93,
    profit: 0.63,
    maxDuration: 10,
    features: ['Hollywood quality', 'Ultra-realistic', '4K support']
  }
};

// ============================================
// MAIN VIDEO GENERATOR CLASS
// ============================================

class VideoGenerator {
  constructor(apiKey) {
    this.apiKey = apiKey;
    this.baseHeaders = {
      'Content-Type': 'application/json',
      'x-api-key': apiKey
    };
  }

  // Calculate cost before generation
  calculateCost(tier, duration) {
    const config = PRICING_TIERS[tier];
    if (!config) {
      throw new Error(`Invalid tier: ${tier}`);
    }
    
    if (duration > config.maxDuration) {
      throw new Error(`Duration exceeds maximum for ${tier} tier (${config.maxDuration}s)`);
    }

    return {
      customerCharge: parseFloat((duration * config.customerPrice).toFixed(2)),
      polloCost: parseFloat((duration * config.baseCost).toFixed(2)),
      profit: parseFloat((duration * config.profit).toFixed(2)),
      duration,
      tier: config.name
    };
  }

  // Main generation method
  async generate(tier, options) {
    const config = PRICING_TIERS[tier];
    
    if (!config) {
      throw new Error(`Invalid tier: ${tier}`);
    }

    // Validate duration
    if (options.duration > config.maxDuration) {
      throw new Error(`Maximum duration for ${tier} is ${config.maxDuration} seconds`);
    }

    // Build tier-specific payload
    const payload = this._buildPayload(tier, options);

    console.log(`🎬 Generating ${tier} video (${options.duration}s)...`);
    console.log(`💰 Customer charge: $${this.calculateCost(tier, options.duration).customerCharge}`);

    try {
      const response = await fetch(config.endpoint, {
        method: 'POST',
        headers: this.baseHeaders,
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(`Pollo API Error: ${error.message || response.statusText}`);
      }

      const data = await response.json();
      
      console.log(`✅ Job submitted! Task ID: ${data.taskId}`);
      
      return {
        success: true,
        taskId: data.taskId,
        status: data.status,
        tier: config.name,
        cost: this.calculateCost(tier, options.duration),
        estimatedTime: '2-5 minutes'
      };

    } catch (error) {
      console.error(`❌ Generation failed:`, error.message);
      throw error;
    }
  }

  // Build API payload based on tier
  _buildPayload(tier, options) {
    const webhookUrl = options.webhookUrl || process.env.WEBHOOK_URL;

    switch(tier) {
      case 'economy':
        return {
          input: {
            prompt: options.prompt,
            negativePrompt: options.negativePrompt,
            image: options.image,
            imageTail: options.imageTail,
            length: options.duration,
            strength: options.strength || 50,
            mode: options.mode || 'std'
          },
          webhookUrl
        };

      case 'basic':
        return {
          input: {
            prompt: options.prompt,
            image: options.image,
            imageTail: options.imageTail,
            resolution: options.resolution || '480p',
            mode: options.mode || 'basic',
            length: options.duration,
            seed: options.seed || Math.floor(Math.random() * 100000)
          },
          webhookUrl
        };

      case 'pro':
        return {
          input: {
            prompt: options.prompt,
            negativePrompt: options.negativePrompt,
            image: options.image,
            strength: options.strength || 50, // 0-100
            length: options.duration
          },
          webhookUrl
        };

      case 'premium':
        return {
          input: {
            prompt: options.prompt,
            negativePrompt: options.negativePrompt,
            image: options.image,
            resolution: options.resolution || '1920x1080',
            duration: options.duration,
            motionStrength: options.motionStrength
          },
          webhookUrl
        };

      default:
        throw new Error(`Unknown tier: ${tier}`);
    }
  }

  // Check generation status (if not using webhooks)
  async checkStatus(taskId) {
    // Note: Pollo.ai status endpoint not documented in your info
    // You'll need to implement polling or use webhooks
    console.log(`Checking status for task: ${taskId}`);
    // TODO: Implement status checking if Pollo provides endpoint
  }

  // Get tier information
  getTierInfo(tier) {
    return PRICING_TIERS[tier];
  }

  // List all available tiers
  listTiers() {
    return Object.entries(PRICING_TIERS).map(([id, config]) => ({
      id,
      name: config.name,
      model: config.model,
      pricePerSecond: `$${config.customerPrice}/sec`,
      maxDuration: `${config.maxDuration}s`,
      features: config.features
    }));
  }
}

// ============================================
// EXAMPLE USAGE
// ============================================

async function exampleUsage() {
  const generator = new VideoGenerator(POLLO_API_KEY);

  console.log('\n📋 Available Tiers:');
  console.log(JSON.stringify(generator.listTiers(), null, 2));

  // Example 0: Economy Tier - Budget-Friendly Text to Video
  console.log('\n\n=== ECONOMY TIER EXAMPLE ===');
  try {
    const result0 = await generator.generate('economy', {
      prompt: 'A cat stretching and yawning on a sunny windowsill',
      negativePrompt: 'blur, low quality',
      duration: 5,
      strength: 60,
      webhookUrl: 'https://yourapp.com/api/webhooks/pollo'
    });
    console.log('Result:', result0);
  } catch (error) {
    console.error('Error:', error.message);
  }

  // Example 1: Basic Tier - Text to Video
  console.log('\n\n=== BASIC TIER EXAMPLE ===');
  try {
    const result1 = await generator.generate('basic', {
      prompt: 'A golden retriever playing in a sunlit park',
      duration: 5,
      webhookUrl: 'https://yourapp.com/api/webhooks/pollo'
    });
    console.log('Result:', result1);
  } catch (error) {
    console.error('Error:', error.message);
  }

  // Example 2: Pro Tier - Image to Video
  console.log('\n\n=== PRO TIER EXAMPLE ===');
  try {
    const result2 = await generator.generate('pro', {
      prompt: 'Camera slowly zooms into the character, dramatic lighting',
      image: 'https://example.com/character.jpg', // or base64
      negativePrompt: 'blur, distortion, artifacts',
      strength: 70,
      duration: 8,
      webhookUrl: 'https://yourapp.com/api/webhooks/pollo'
    });
    console.log('Result:', result2);
  } catch (error) {
    console.error('Error:', error.message);
  }

  // Example 3: Premium Tier - High Quality
  console.log('\n\n=== PREMIUM TIER EXAMPLE ===');
  try {
    const result3 = await generator.generate('premium', {
      prompt: 'F-14 Tomcat fighter jet taking off from aircraft carrier at sunset',
      negativePrompt: 'low quality, blur',
      resolution: '1920x1080',
      duration: 10,
      motionStrength: 0.8,
      webhookUrl: 'https://yourapp.com/api/webhooks/pollo'
    });
    console.log('Result:', result3);
  } catch (error) {
    console.error('Error:', error.message);
  }

  // Example 4: Cost Calculation
  console.log('\n\n=== COST CALCULATIONS ===');
  ['economy', 'basic', 'pro', 'premium'].forEach(tier => {
    const cost5s = generator.calculateCost(tier, 5);
    const cost10s = generator.calculateCost(tier, 10);
    
    console.log(`\n${PRICING_TIERS[tier].name}:`);
    console.log(`  5 seconds:  Charge customer $${cost5s.customerCharge}, Profit: $${cost5s.profit}`);
    console.log(`  10 seconds: Charge customer $${cost10s.customerCharge}, Profit: $${cost10s.profit}`);
  });
}

// ============================================
// WEBHOOK HANDLER (Express.js)
// ============================================

const express = require('express');
const app = express();
app.use(express.json());

// Handle Pollo.ai webhooks
app.post('/api/webhooks/pollo', async (req, res) => {
  const { taskId, status, videoUrl } = req.body;

  console.log(`📨 Webhook received for task ${taskId}: ${status}`);

  try {
    // Find the job in your database
    const job = await findJobByTaskId(taskId); // Implement this

    if (!job) {
      console.error(`❌ Job not found for taskId: ${taskId}`);
      return res.status(404).json({ error: 'Job not found' });
    }

    if (status === 'succeed') {
      // Success! Update database and notify user
      await updateJob(job.id, {
        status: 'completed',
        videoUrl: videoUrl,
        completedAt: new Date()
      });

      await notifyUser(job.userId, {
        success: true,
        videoUrl: videoUrl,
        message: 'Your video is ready!'
      });

      console.log(`✅ Job ${taskId} completed successfully`);

    } else if (status === 'failed') {
      // Failure - refund user
      await updateJob(job.id, {
        status: 'failed',
        completedAt: new Date()
      });

      // Refund the charged amount
      await refundUser(job.userId, job.chargedAmount);

      await notifyUser(job.userId, {
        success: false,
        message: 'Generation failed. Your credits have been refunded.'
      });

      console.log(`❌ Job ${taskId} failed - user refunded`);
    }

    res.json({ success: true });

  } catch (error) {
    console.error('Webhook processing error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ============================================
// DATABASE HELPER FUNCTIONS (IMPLEMENT THESE)
// ============================================

async function findJobByTaskId(taskId) {
  // Query your database for job with this taskId
  // return { id, userId, tier, chargedAmount, ... }
}

async function updateJob(jobId, updates) {
  // Update job record in database
}

async function refundUser(userId, amount) {
  // Add credits back to user's balance
  // Log transaction
}

async function notifyUser(userId, data) {
  // Send email/push notification to user
}

// ============================================
// USER-FACING API ENDPOINT
// ============================================

app.post('/api/videos/generate', async (req, res) => {
  const { tier, prompt, image, duration } = req.body;
  const userId = req.user.id; // from authentication middleware

  try {
    const generator = new VideoGenerator(POLLO_API_KEY);
    
    // 1. Calculate cost
    const cost = generator.calculateCost(tier, duration);
    
    // 2. Check user balance
    const user = await getUserById(userId);
    if (user.creditsBalance < cost.customerCharge) {
      return res.status(402).json({
        error: 'Insufficient credits',
        required: cost.customerCharge,
        current: user.creditsBalance
      });
    }
    
    // 3. Deduct credits immediately
    await deductCredits(userId, cost.customerCharge);
    
    // 4. Create job record
    const job = await createJob({
      userId,
      tier,
      prompt,
      image,
      duration,
      chargedAmount: cost.customerCharge,
      polloCost: cost.polloCost,
      profit: cost.profit,
      status: 'pending'
    });
    
    // 5. Submit to Pollo.ai
    const result = await generator.generate(tier, {
      prompt,
      image,
      duration,
      webhookUrl: `${process.env.APP_URL}/api/webhooks/pollo`
    });
    
    // 6. Update job with taskId
    await updateJob(job.id, {
      taskId: result.taskId,
      status: 'processing'
    });
    
    res.json({
      jobId: job.id,
      taskId: result.taskId,
      status: 'processing',
      charged: cost.customerCharge,
      estimatedTime: result.estimatedTime
    });
    
  } catch (error) {
    console.error('Generation error:', error);
    
    // Refund on error
    if (cost) {
      await addCredits(userId, cost.customerCharge);
    }
    
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// EXPORTS
// ============================================

module.exports = {
  VideoGenerator,
  PRICING_TIERS
};

// ============================================
// RUN EXAMPLES (uncomment to test)
// ============================================

// exampleUsage().catch(console.error);

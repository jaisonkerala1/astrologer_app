const express = require('express');
const router = express.Router();
const Astrologer = require('../models/Astrologer');
const twilioService = require('../services/twilioService');

// Test MongoDB connection
router.get('/test-mongodb', async (req, res) => {
  try {
    const count = await Astrologer.countDocuments();
    res.json({
      success: true,
      message: 'MongoDB connection successful',
      userCount: count
    });
  } catch (error) {
    console.error('MongoDB test error:', error);
    res.status(500).json({
      success: false,
      message: 'MongoDB connection failed',
      error: error.message
    });
  }
});

// Test Twilio directly (bypass MongoDB)
router.post('/test-twilio', async (req, res) => {
  try {
    const { phone } = req.body;
    
    console.log('Testing Twilio with phone:', phone);
    console.log('TWILIO_ACCOUNT_SID:', process.env.TWILIO_ACCOUNT_SID ? 'SET' : 'NOT SET');
    console.log('TWILIO_AUTH_TOKEN:', process.env.TWILIO_AUTH_TOKEN ? 'SET' : 'NOT SET');
    console.log('TWILIO_PHONE_NUMBER:', process.env.TWILIO_PHONE_NUMBER);
    
    // Test Twilio service directly
    const result = await twilioService.sendOTP(phone, '123456');
    
    res.json({
      success: true,
      message: 'Twilio test successful',
      result: result
    });
  } catch (error) {
    console.error('Twilio test error:', error);
    res.status(500).json({
      success: false,
      message: 'Twilio test failed',
      error: error.message
    });
  }
});

// Test MongoDB connection and create a test user
router.post('/create-test-user', async (req, res) => {
  try {
    const { phone, name, email } = req.body;
    
    // Check if user already exists
    let astrologer = await Astrologer.findOne({ phone });
    if (astrologer) {
      return res.json({
        success: true,
        message: 'User already exists',
        data: astrologer
      });
    }

    // Create new test user
    astrologer = new Astrologer({
      phone: phone || '+918050381803',
      name: name || 'Test User',
      email: email || 'test@example.com',
      specializations: ['Vedic Astrology'],
      languages: ['English'],
      experience: 1,
      ratePerMinute: 50,
      isOnline: false,
      totalEarnings: 0
    });

    await astrologer.save();

    res.json({
      success: true,
      message: 'Test user created successfully',
      data: astrologer
    });
  } catch (error) {
    console.error('Test user creation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create test user',
      error: error.message
    });
  }
});

module.exports = router;
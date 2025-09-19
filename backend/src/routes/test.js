const express = require('express');
const router = express.Router();
const Astrologer = require('../models/Astrologer');

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

module.exports = router;

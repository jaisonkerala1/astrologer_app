const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const Astrologer = require('../models/Astrologer');
const User = require('../models/User');

/**
 * POST /api/fcm/register
 * Register FCM token for push notifications
 */
router.post('/register', authMiddleware, async (req, res) => {
  try {
    const { fcmToken, platform } = req.body;
    // Our auth middleware (astrologer app) sets: req.user = { astrologerId, sessionId }
    // Other auth flows may set: req.user = { id/userId/_id, userType/type/role }
    const userId =
      req.user?.astrologerId ||
      req.user?.id ||
      req.user?.userId ||
      req.user?._id;

    const userType =
      req.user?.userType ||
      req.user?.type ||
      req.user?.role ||
      (req.user?.astrologerId ? 'astrologer' : 'user');
    
    if (!fcmToken) {
      return res.status(400).json({
        success: false,
        message: 'FCM token is required',
      });
    }
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID not found in token',
      });
    }
    
    // Select model based on user type
    const Model = userType === 'astrologer' ? Astrologer : User;
    
    // Find user and update FCM tokens
    const user = await Model.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }
    
    // Initialize fcmTokens array if it doesn't exist
    if (!user.fcmTokens) {
      user.fcmTokens = [];
    }
    
    // Remove old token if exists (same device)
    user.fcmTokens = user.fcmTokens.filter(t => t.token !== fcmToken);
    
    // Add new token
    user.fcmTokens.push({
      token: fcmToken,
      platform: platform || 'android',
      lastUpdated: new Date(),
    });
    
    // Keep only last 3 tokens per user (multiple devices)
    if (user.fcmTokens.length > 3) {
      user.fcmTokens = user.fcmTokens.slice(-3);
    }
    
    await user.save();
    
    console.log(`✅ [FCM] Token registered for ${userType}: ${userId}`);
    
    res.json({
      success: true,
      message: 'FCM token registered successfully',
    });
  } catch (error) {
    console.error('❌ [FCM] Token registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to register FCM token',
      error: error.message,
    });
  }
});

/**
 * POST /api/fcm/unregister
 * Remove FCM token (on logout)
 */
router.post('/unregister', authMiddleware, async (req, res) => {
  try {
    const { fcmToken } = req.body;
    const userId =
      req.user?.astrologerId ||
      req.user?.id ||
      req.user?.userId ||
      req.user?._id;

    const userType =
      req.user?.userType ||
      req.user?.type ||
      req.user?.role ||
      (req.user?.astrologerId ? 'astrologer' : 'user');
    
    if (!fcmToken) {
      return res.status(400).json({
        success: false,
        message: 'FCM token is required',
      });
    }
    
    const Model = userType === 'astrologer' ? Astrologer : User;
    
    await Model.findByIdAndUpdate(userId, {
      $pull: { fcmTokens: { token: fcmToken } },
    });
    
    console.log(`✅ [FCM] Token unregistered for ${userType}: ${userId}`);
    
    res.json({
      success: true,
      message: 'FCM token removed successfully',
    });
  } catch (error) {
    console.error('❌ [FCM] Token removal error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to remove FCM token',
      error: error.message,
    });
  }
});

/**
 * GET /api/fcm/tokens
 * Get user's registered FCM tokens (for debugging)
 */
router.get('/tokens', authMiddleware, async (req, res) => {
  try {
    const userId =
      req.user?.astrologerId ||
      req.user?.id ||
      req.user?.userId ||
      req.user?._id;

    const userType =
      req.user?.userType ||
      req.user?.type ||
      req.user?.role ||
      (req.user?.astrologerId ? 'astrologer' : 'user');
    
    const Model = userType === 'astrologer' ? Astrologer : User;
    const user = await Model.findById(userId).select('fcmTokens');
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }
    
    res.json({
      success: true,
      tokens: user.fcmTokens || [],
    });
  } catch (error) {
    console.error('❌ [FCM] Get tokens error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get FCM tokens',
      error: error.message,
    });
  }
});

module.exports = router;




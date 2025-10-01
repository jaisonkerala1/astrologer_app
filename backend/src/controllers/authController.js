const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const crypto = require('crypto');
const Astrologer = require('../models/Astrologer');
const Otp = require('../models/Otp');
const twilioService = require('../services/twilioService');
const normalizeAstrologer = require('../utils/astrologerResponse');

// Generate JWT token
const generateToken = (astrologerId, sessionId) => {
  return jwt.sign(
    { astrologerId, sessionId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
};

// Send OTP
const sendOTP = async (req, res) => {
  try {
    const { phone } = req.body;

    // Check if MongoDB is connected
    if (mongoose.connection.readyState !== 1) {
      console.log('MongoDB not connected, readyState:', mongoose.connection.readyState);
      return res.status(503).json({ 
        success: false, 
        message: 'Service temporarily unavailable. Please try again in a moment.' 
      });
    }

    // Validate phone number
    if (!phone || phone.length < 10) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid phone number'
      });
    }

    // Generate OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Create OTP record in MongoDB
    const otpRecord = new Otp({
      phone,
      otp,
      expiresAt: new Date(Date.now() + 5 * 60 * 1000) // 5 minutes
    });
    await otpRecord.save();
    
    // Send OTP via Twilio
    try {
      await twilioService.sendOTP(phone, otp);
      console.log(`OTP sent to ${phone}: ${otp}`);
    } catch (error) {
      console.error('Twilio error:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to send OTP. Please try again.'
      });
    }

    res.json({
      success: true,
      message: 'OTP sent successfully to your phone number',
      otpId: otpRecord.id
    });
  } catch (error) {
    console.error('Send OTP error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send OTP'
    });
  }
};

// Verify OTP and login
const verifyOTP = async (req, res) => {
  try {
    const { phone, otp, otpId } = req.body;

    // Validate input
    if (!phone || !otp) {
      return res.status(400).json({
        success: false,
        message: 'Phone number and OTP are required'
      });
    }

    // Verify OTP
    const otpRecord = await Otp.findOne({
      phone,
      otp,
      isUsed: false,
      expiresAt: { $gt: new Date() },
      attempts: { $lt: 3 }
    }).sort({ createdAt: -1 });

    if (!otpRecord) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired OTP'
      });
    }

    // Mark OTP as used
    otpRecord.isUsed = true;
    await otpRecord.save();

    // Find existing astrologer (don't create new ones in login)
    let astrologer = await Astrologer.findOne({ phone });
    
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Account not found. Please sign up first.'
      });
    }

    // Generate token
    const sessionId = crypto.randomUUID();
    astrologer.activeSession = {
      sessionId,
      deviceInfo: {
        userAgent: req.headers['user-agent'] || null,
        platform: req.headers['sec-ch-ua-platform'] || null,
        ipAddress: req.ip || req.headers['x-forwarded-for'] || null
      },
      createdAt: new Date(),
      lastSeenAt: new Date()
    };
    astrologer.isOnline = true;
    await astrologer.save();

    const token = generateToken(astrologer.id, sessionId);

    res.json({
      success: true,
      message: 'Login successful',
      token,
      astrologer: normalizeAstrologer(astrologer),
      sessionId,
      activeSession: astrologer.activeSession
    });
  } catch (error) {
    console.error('Verify OTP error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to verify OTP'
    });
  }
};

// Signup new astrologer
const signup = async (req, res) => {
  try {
    const { phone, otp, otpId, name, email, experience, specializations, languages, bio, awards, certificates } = req.body;

    // Check if profile picture is uploaded
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Profile picture is required for signup'
      });
    }

    // Verify OTP first
    const otpRecord = await Otp.findOne({
      phone,
      otp,
      isUsed: false,
      expiresAt: { $gt: new Date() },
      attempts: { $lt: 3 }
    }).sort({ createdAt: -1 });

    if (!otpRecord) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired OTP'
      });
    }

    // Mark OTP as used
    otpRecord.isUsed = true;
    await otpRecord.save();

    // Check if astrologer already exists
    let astrologer = await Astrologer.findOne({ phone });
    
    if (astrologer) {
      return res.status(400).json({
        success: false,
        message: 'Account with this phone number already exists'
      });
    }

    // Get profile picture URL from uploaded file
    const profilePictureUrl = `/uploads/${req.file.filename}`;

    // Create new astrologer with provided data including bio fields
    astrologer = new Astrologer({
      phone,
      name: name || 'Astrologer',
      email: email || `${phone}@astrologer.com`,
      profilePicture: profilePictureUrl,
      specializations: specializations || ['Vedic Astrology'],
      languages: languages || ['English'],
      experience: experience || 0,
      ratePerMinute: 50,
      isOnline: false,
      totalEarnings: 0,
      // Use provided bio fields or default to empty strings
      bio: bio || '',
      awards: awards || '',
      certificates: certificates || ''
    });

    // Save astrologer to MongoDB
    await astrologer.save();

    // Generate token
    const sessionId = crypto.randomUUID();
    astrologer.activeSession = {
      sessionId,
      deviceInfo: {
        userAgent: req.headers['user-agent'] || null,
        platform: req.headers['sec-ch-ua-platform'] || null,
        ipAddress: req.ip || req.headers['x-forwarded-for'] || null
      },
      createdAt: new Date(),
      lastSeenAt: new Date()
    };
    astrologer.isOnline = true;
    await astrologer.save();

    const token = generateToken(astrologer.id, sessionId);

    res.json({
      success: true,
      message: 'Account created successfully',
      token,
      astrologer: normalizeAstrologer(astrologer),
      sessionId,
      activeSession: astrologer.activeSession
    });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create account'
    });
  }
};

// Refresh token
const refreshToken = async (req, res) => {
  try {
    const { astrologerId, sessionId } = req.user;
    
    const astrologer = await Astrologer.findById(astrologerId);
    if (!astrologer) {
      return res.status(401).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    if (!astrologer.activeSession || astrologer.activeSession.sessionId !== sessionId) {
      return res.status(401).json({
        success: false,
        message: 'Session expired. Please log in again.'
      });
    }

    astrologer.activeSession.lastSeenAt = new Date();
    await astrologer.save();

    const token = generateToken(astrologer.id, astrologer.activeSession.sessionId);

    res.json({
      success: true,
      message: 'Token refreshed successfully',
      token,
      astrologer: normalizeAstrologer(astrologer),
      sessionId: astrologer.activeSession.sessionId,
      activeSession: astrologer.activeSession
    });
  } catch (error) {
    console.error('Refresh token error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to refresh token'
    });
  }
};

// Logout
const logout = async (req, res) => {
  try {
    const { astrologerId } = req.user;
    const astrologer = await Astrologer.findById(astrologerId);

    if (astrologer?.activeSession) {
      astrologer.activeSession = null;
      astrologer.isOnline = false;
      astrologer.lastSeen = new Date();
      await astrologer.save();
    }

    res.json({
      success: true,
      message: 'Logout successful'
    });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to logout'
    });
  }
};

// Delete account permanently
const deleteAccount = async (req, res) => {
  try {
    const { astrologerId } = req.user;
    
    // Find the astrologer
    const astrologer = await Astrologer.findById(astrologerId);
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Account not found'
      });
    }

    // Delete the astrologer from MongoDB
    await Astrologer.findByIdAndDelete(astrologerId);
    
    // Also delete any associated OTP records for this phone
    await Otp.deleteMany({ phone: astrologer.phone });

    console.log(`Account permanently deleted for astrologer ID: ${astrologerId} - MongoDB persistent storage`);

    res.json({
      success: true,
      message: 'Account has been permanently deleted'
    });
  } catch (error) {
    console.error('Delete account error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete account'
    });
  }
};

module.exports = {
  sendOTP,
  verifyOTP,
  signup,
  refreshToken,
  logout,
  deleteAccount
};






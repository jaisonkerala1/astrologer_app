const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const Astrologer = require('../models/Astrologer');
const Otp = require('../models/Otp');
const twilioService = require('../services/twilioService');

// Generate JWT token
const generateToken = (astrologerId) => {
  return jwt.sign(
    { astrologerId },
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
    const token = generateToken(astrologer.id);

    res.json({
      success: true,
      message: 'Login successful',
      token,
      astrologer: {
        id: astrologer.id,
        phone: astrologer.phone,
        name: astrologer.name,
        email: astrologer.email,
        profilePicture: astrologer.profilePicture,
        specializations: astrologer.specializations,
        languages: astrologer.languages,
        experience: astrologer.experience,
        ratePerMinute: astrologer.ratePerMinute,
        isOnline: astrologer.isOnline,
        totalEarnings: astrologer.totalEarnings,
        createdAt: astrologer.createdAt,
        updatedAt: astrologer.updatedAt
      }
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
    const { phone, otp, otpId, name, email, experience, specializations, languages, bio, certifications, awards } = req.body;
    
    console.log('🔍 SIGNUP DEBUG - Data received:');
    console.log('Phone:', phone);
    console.log('Name:', name);
    console.log('Email:', email);
    console.log('Bio:', bio);
    console.log('Certifications:', certifications);
    console.log('Awards:', awards);
    console.log('Full body:', req.body);

    // Verify OTP first
    console.log('🔍 SIGNUP DEBUG - Verifying OTP for phone:', phone, 'OTP:', otp);
    const otpRecord = await Otp.findOne({
      phone,
      otp,
      isUsed: false,
      expiresAt: { $gt: new Date() },
      attempts: { $lt: 3 }
    }).sort({ createdAt: -1 });

    console.log('🔍 SIGNUP DEBUG - OTP record found:', otpRecord ? 'YES' : 'NO');
    if (otpRecord) {
      console.log('🔍 SIGNUP DEBUG - OTP record details:', {
        phone: otpRecord.phone,
        otp: otpRecord.otp,
        isUsed: otpRecord.isUsed,
        expiresAt: otpRecord.expiresAt,
        attempts: otpRecord.attempts
      });
    }

    if (!otpRecord) {
      console.log('🔍 SIGNUP DEBUG - OTP verification failed - returning error');
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

    // Create new astrologer with provided data
    astrologer = new Astrologer({
      phone,
      name: name || 'Astrologer',
      email: email || `${phone}@astrologer.com`,
      profilePicture: null,
      specializations: specializations || ['Vedic Astrology'],
      languages: languages || ['English'],
      experience: experience || 0,
      ratePerMinute: 50,
      isOnline: false,
      totalEarnings: 0,
      bio: bio || '',
      certifications: certifications || [],
      awards: awards || []
    });

    console.log('🔍 SIGNUP DEBUG - Astrologer object before save:');
    console.log('Bio:', astrologer.bio);
    console.log('Certifications:', astrologer.certifications);
    console.log('Awards:', astrologer.awards);

    // Save astrologer to MongoDB
    await astrologer.save();
    
    console.log('🔍 SIGNUP DEBUG - Astrologer saved successfully');
    console.log('Saved Bio:', astrologer.bio);
    console.log('Saved Certifications:', astrologer.certifications);
    console.log('Saved Awards:', astrologer.awards);

    // Generate token
    const token = generateToken(astrologer.id);

    res.json({
      success: true,
      message: 'Account created successfully',
      token,
      astrologer: {
        id: astrologer.id,
        phone: astrologer.phone,
        name: astrologer.name,
        email: astrologer.email,
        profilePicture: astrologer.profilePicture,
        specializations: astrologer.specializations,
        languages: astrologer.languages,
        experience: astrologer.experience,
        ratePerMinute: astrologer.ratePerMinute,
        isOnline: astrologer.isOnline,
        totalEarnings: astrologer.totalEarnings,
        bio: astrologer.bio,
        certifications: astrologer.certifications,
        awards: astrologer.awards,
        createdAt: astrologer.createdAt,
        updatedAt: astrologer.updatedAt
      }
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
    const { astrologerId } = req.user;
    
    const astrologer = await Astrologer.findById(astrologerId);
    if (!astrologer) {
      return res.status(401).json({
        success: false,
        message: 'Astrologer not found'
      });
    }

    const token = generateToken(astrologer.id);

    res.json({
      success: true,
      message: 'Token refreshed successfully',
      token
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
    // For JWT, logout is handled client-side by removing the token
    // In a more complex system, you might maintain a blacklist of tokens
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






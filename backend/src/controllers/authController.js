const jwt = require('jsonwebtoken');
const memoryStorage = require('../services/memoryStorage');
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

    // Validate phone number
    if (!phone || phone.length < 10) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid phone number'
      });
    }

    // Generate OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpRecord = memoryStorage.createOTP(phone, otp);
    
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
    const otpRecord = memoryStorage.verifyOTP(phone, otp, otpId);
    if (!otpRecord) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired OTP'
      });
    }

    // Find existing astrologer (don't create new ones in login)
    let astrologer = memoryStorage.findAstrologerByPhone(phone);
    
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
    const { phone, otp, otpId, name, email, experience, specializations, languages } = req.body;

    // Verify OTP first
    const otpRecord = memoryStorage.verifyOTP(phone, otp, otpId);
    if (!otpRecord) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired OTP'
      });
    }

    // Check if astrologer already exists
    let astrologer = memoryStorage.findAstrologerByPhone(phone);
    
    if (astrologer) {
      return res.status(400).json({
        success: false,
        message: 'Account with this phone number already exists'
      });
    }

    // Create new astrologer with provided data
    astrologer = {
      id: Date.now().toString(),
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
      createdAt: new Date(),
      updatedAt: new Date()
    };

    // Save astrologer
    memoryStorage.astrologers.set(astrologer.id, astrologer);

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
    
    const astrologer = memoryStorage.findAstrologerById(astrologerId);
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
    const astrologer = memoryStorage.findAstrologerById(astrologerId);
    if (!astrologer) {
      return res.status(404).json({
        success: false,
        message: 'Account not found'
      });
    }

    // Delete the astrologer from memory storage
    memoryStorage.astrologers.delete(astrologerId);
    
    // Also delete any associated OTP records for this phone
    const phone = astrologer.phone;
    for (const [otpId, otpRecord] of memoryStorage.otpRecords.entries()) {
      if (otpRecord.phone === phone) {
        memoryStorage.otpRecords.delete(otpId);
      }
    }

    console.log(`Account permanently deleted for astrologer ID: ${astrologerId}`);

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






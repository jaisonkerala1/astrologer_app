const jwt = require('jsonwebtoken');
const Astrologer = require('../models/Astrologer');

/**
 * Optional authentication middleware
 * Sets req.user if valid token is provided, but doesn't fail if no token
 * Used for endpoints that work with or without authentication
 */
const optionalAuth = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');

    // If no token, just continue without setting req.user
    if (!token) {
      console.log('🔓 No token provided - continuing as unauthenticated');
      return next();
    }

    // If token exists, verify it
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const astrologer = await Astrologer.findById(decoded.astrologerId);

    if (!astrologer) {
      console.log('❌ Invalid token - astrologer not found');
      return next(); // Continue without auth instead of failing
    }

    if (!astrologer.activeSession || astrologer.activeSession.sessionId !== decoded.sessionId) {
      console.log('❌ Session invalid or expired');
      return next(); // Continue without auth instead of failing
    }

    // Update last seen
    astrologer.activeSession.lastSeenAt = new Date();
    await astrologer.save();

    // Set req.user for authenticated requests
    req.user = { 
      astrologerId: astrologer._id, 
      sessionId: decoded.sessionId,
      userType: 'astrologer' 
    };
    console.log('✅ User authenticated:', req.user.astrologerId);
    next();
  } catch (error) {
    // On any error, just continue without auth (don't fail the request)
    console.log('⚠️ Auth error (continuing unauthenticated):', error.message);
    next();
  }
};

module.exports = optionalAuth;


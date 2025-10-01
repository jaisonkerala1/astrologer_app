const jwt = require('jsonwebtoken');
const Astrologer = require('../models/Astrologer');

const auth = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No token provided.'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const astrologer = await Astrologer.findById(decoded.astrologerId);

    if (!astrologer) {
      return res.status(401).json({
        success: false,
        message: 'Invalid token. Astrologer not found.'
      });
    }

    if (!astrologer.activeSession || astrologer.activeSession.sessionId !== decoded.sessionId) {
      return res.status(401).json({
        success: false,
        message: 'Session invalid or expired. Please log in again.'
      });
    }

    astrologer.activeSession.lastSeenAt = new Date();
    await astrologer.save();

    req.user = { astrologerId: astrologer._id, sessionId: decoded.sessionId };
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Invalid token.'
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token expired.'
      });
    }

    console.error('Auth middleware error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error.'
    });
  }
};

module.exports = auth;










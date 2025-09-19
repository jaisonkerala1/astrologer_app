const jwt = require('jsonwebtoken');
const memoryStorage = require('../services/memoryStorage');

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
    const astrologer = memoryStorage.findAstrologerById(decoded.astrologerId);

    if (!astrologer) {
      return res.status(401).json({
        success: false,
        message: 'Invalid token. Astrologer not found.'
      });
    }

    req.user = { astrologerId: astrologer.id };
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










/**
 * Socket.IO Authentication Middleware
 * Validates JWT token from socket handshake
 */

const jwt = require('jsonwebtoken');
const Astrologer = require('../models/Astrologer');

/**
 * Authenticate socket connection
 */
const socketAuth = async (socket, next) => {
  try {
    const token = socket.handshake.auth.token;

    if (!token) {
      console.log('🔒 [SOCKET AUTH] No token provided');
      return next(new Error('Authentication required'));
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const astrologer = await Astrologer.findById(decoded.astrologerId);
    
    if (!astrologer) {
      return next(new Error('User not found'));
    }

    if (!astrologer.activeSession || astrologer.activeSession.sessionId !== decoded.sessionId) {
      return next(new Error('Session expired'));
    }

    socket.user = {
      id: astrologer._id.toString(),
      astrologerId: astrologer._id.toString(),
      name: astrologer.name,
      profileImage: astrologer.profileImage,
      sessionId: decoded.sessionId,
    };

    console.log(`✅ [SOCKET AUTH] ${astrologer.name} connected (${socket.id})`);
    next();
  } catch (error) {
    console.error('🔒 [SOCKET AUTH] Error:', error.message);
    next(new Error('Authentication failed'));
  }
};

/**
 * Optional auth - allows anonymous connections
 */
const optionalSocketAuth = async (socket, next) => {
  try {
    const token = socket.handshake.auth.token;

    if (!token) {
      socket.user = { id: `anon_${socket.id}`, name: 'Anonymous', isAnonymous: true };
      return next();
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const astrologer = await Astrologer.findById(decoded.astrologerId);
    
    if (astrologer && astrologer.activeSession?.sessionId === decoded.sessionId) {
      socket.user = {
        id: astrologer._id.toString(),
        astrologerId: astrologer._id.toString(),
        name: astrologer.name,
        profileImage: astrologer.profileImage,
        isAnonymous: false,
      };
    } else {
      socket.user = { id: `anon_${socket.id}`, name: 'Anonymous', isAnonymous: true };
    }
    next();
  } catch (error) {
    socket.user = { id: `anon_${socket.id}`, name: 'Anonymous', isAnonymous: true };
    next();
  }
};

module.exports = { socketAuth, optionalSocketAuth };

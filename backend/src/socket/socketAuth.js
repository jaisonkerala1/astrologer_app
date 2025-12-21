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
 * Optional auth - allows anonymous connections + admin connections
 */
const optionalSocketAuth = async (socket, next) => {
  try {
    const token = socket.handshake.auth.token;

    if (!token) {
      socket.user = { id: `anon_${socket.id}`, name: 'Anonymous', isAnonymous: true };
      return next();
    }

    // Check if it's admin token (simple secret key)
    if (token === process.env.ADMIN_SECRET_KEY || token === 'admin123') {
      socket.user = {
        id: 'admin',
        name: 'Admin',
        role: 'admin',
        isAnonymous: false,
        isAdmin: true,
      };
      socket.userId = 'admin';
      socket.userType = 'admin';
      console.log(`✅ [SOCKET AUTH] Admin connected (${socket.id})`);
      return next();
    }

    // Check if it's astrologer JWT token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    console.log(`🔐 [SOCKET AUTH] Token decoded successfully for astrologer: ${decoded.astrologerId}`);
    
    const astrologer = await Astrologer.findById(decoded.astrologerId);
    
    if (!astrologer) {
      console.warn(`⚠️ [SOCKET AUTH] Astrologer not found: ${decoded.astrologerId}`);
      socket.user = { id: `anon_${socket.id}`, name: 'Anonymous', isAnonymous: true };
      return next();
    }
    
    if (!astrologer.activeSession || astrologer.activeSession.sessionId !== decoded.sessionId) {
      console.warn(`⚠️ [SOCKET AUTH] Session mismatch for ${astrologer.name}: expected ${decoded.sessionId}, got ${astrologer.activeSession?.sessionId}`);
      socket.user = { id: `anon_${socket.id}`, name: 'Anonymous', isAnonymous: true };
      return next();
    }
    
    // Successfully authenticated as astrologer
    socket.user = {
      id: astrologer._id.toString(),
      astrologerId: astrologer._id.toString(),
      name: astrologer.name,
      profileImage: astrologer.profileImage,
      role: 'astrologer',
      isAnonymous: false,
    };
    socket.userId = astrologer._id.toString();
    socket.userType = 'astrologer';
    console.log(`✅ [SOCKET AUTH] Astrologer authenticated: ${astrologer.name} (${socket.userId})`);
    next();
  } catch (error) {
    console.error(`❌ [SOCKET AUTH] Authentication failed: ${error.message}`);
    socket.user = { id: `anon_${socket.id}`, name: 'Anonymous', isAnonymous: true };
    next();
  }
};

module.exports = { socketAuth, optionalSocketAuth };

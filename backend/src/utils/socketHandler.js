/**
 * Socket.IO Handler for Real-time Discussion Features
 * Manages real-time comments, likes, and notifications
 */

const jwt = require('jsonwebtoken');
const Astrologer = require('../models/Astrologer');

/**
 * Initialize Socket.IO server
 */
function initializeSocket(io) {
  console.log('🔌 Socket.IO server initialized');

  // Middleware to authenticate socket connections
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      
      if (!token) {
        // Allow anonymous connections (for viewing public discussions)
        socket.user = null;
        return next();
      }

      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
      
      // Get user details
      const astrologer = await Astrologer.findById(decoded.id);
      if (astrologer) {
        socket.user = {
          id: astrologer._id,
          name: astrologer.name,
          photo: astrologer.profilePicture,
          userType: 'astrologer'
        };
      } else {
        socket.user = null;
      }
      
      next();
    } catch (error) {
      console.error('Socket authentication error:', error.message);
      // Allow connection but mark as unauthenticated
      socket.user = null;
      next();
    }
  });

  // Connection event
  io.on('connection', (socket) => {
    console.log(`✅ Socket connected: ${socket.id} | User: ${socket.user?.name || 'Anonymous'}`);

    // Track active users
    if (socket.user) {
      socket.emit('authenticated', {
        user: socket.user,
        message: 'Successfully authenticated'
      });
    }

    // ============================================
    // JOIN DISCUSSION ROOMS
    // ============================================

    /**
     * Join a discussion room to receive real-time updates
     * @param {string} discussionId - The discussion ID to join
     */
    socket.on('discussion:join', (discussionId) => {
      socket.join(`discussion:${discussionId}`);
      console.log(`👥 ${socket.user?.name || 'Anonymous'} joined discussion: ${discussionId}`);
      
      // Notify others in the room
      socket.to(`discussion:${discussionId}`).emit('user:joined', {
        user: socket.user,
        timestamp: new Date()
      });

      // Send current viewers count
      const roomSize = io.sockets.adapter.rooms.get(`discussion:${discussionId}`)?.size || 0;
      io.to(`discussion:${discussionId}`).emit('discussion:viewers', {
        discussionId,
        count: roomSize
      });
    });

    /**
     * Leave a discussion room
     * @param {string} discussionId - The discussion ID to leave
     */
    socket.on('discussion:leave', (discussionId) => {
      socket.leave(`discussion:${discussionId}`);
      console.log(`👋 ${socket.user?.name || 'Anonymous'} left discussion: ${discussionId}`);
      
      // Notify others in the room
      socket.to(`discussion:${discussionId}`).emit('user:left', {
        user: socket.user,
        timestamp: new Date()
      });

      // Send updated viewers count
      const roomSize = io.sockets.adapter.rooms.get(`discussion:${discussionId}`)?.size || 0;
      io.to(`discussion:${discussionId}`).emit('discussion:viewers', {
        discussionId,
        count: roomSize
      });
    });

    // ============================================
    // TYPING INDICATORS
    // ============================================

    /**
     * User is typing a comment
     * @param {string} discussionId - The discussion ID
     */
    socket.on('comment:typing', (discussionId) => {
      if (!socket.user) return;
      
      socket.to(`discussion:${discussionId}`).emit('comment:typing', {
        discussionId,
        user: socket.user,
        timestamp: new Date()
      });
    });

    /**
     * User stopped typing
     * @param {string} discussionId - The discussion ID
     */
    socket.on('comment:stop-typing', (discussionId) => {
      if (!socket.user) return;
      
      socket.to(`discussion:${discussionId}`).emit('comment:stop-typing', {
        discussionId,
        user: socket.user,
        timestamp: new Date()
      });
    });

    // ============================================
    // REAL-TIME COMMENT UPDATES
    // ============================================

    /**
     * User is reading a comment (for read receipts)
     * @param {string} commentId - The comment ID
     * @param {string} discussionId - The discussion ID
     */
    socket.on('comment:read', ({ commentId, discussionId }) => {
      if (!socket.user) return;
      
      socket.to(`discussion:${discussionId}`).emit('comment:read', {
        commentId,
        discussionId,
        user: socket.user,
        timestamp: new Date()
      });
    });

    // ============================================
    // REAL-TIME REACTIONS
    // ============================================

    /**
     * Quick reaction to a comment (before API call completes)
     * Provides instant feedback to user
     * @param {string} targetId - Discussion or comment ID
     * @param {string} targetType - 'discussion' or 'comment'
     * @param {string} discussionId - The discussion ID
     */
    socket.on('reaction:optimistic', ({ targetId, targetType, discussionId }) => {
      if (!socket.user) return;
      
      socket.to(`discussion:${discussionId}`).emit('reaction:optimistic', {
        targetId,
        targetType,
        discussionId,
        user: socket.user,
        timestamp: new Date()
      });
    });

    // ============================================
    // PRESENCE & ONLINE STATUS
    // ============================================

    /**
     * Update user presence
     */
    socket.on('presence:update', (status) => {
      if (!socket.user) return;
      
      socket.broadcast.emit('presence:update', {
        user: socket.user,
        status, // 'online', 'away', 'busy'
        timestamp: new Date()
      });
    });

    // ============================================
    // DISCONNECT EVENT
    // ============================================

    socket.on('disconnect', () => {
      console.log(`❌ Socket disconnected: ${socket.id} | User: ${socket.user?.name || 'Anonymous'}`);
      
      // Notify all rooms the user was in
      const rooms = Array.from(socket.rooms);
      rooms.forEach(room => {
        if (room.startsWith('discussion:')) {
          const roomSize = io.sockets.adapter.rooms.get(room)?.size || 0;
          io.to(room).emit('discussion:viewers', {
            discussionId: room.replace('discussion:', ''),
            count: roomSize
          });
        }
      });

      // Broadcast offline status
      if (socket.user) {
        socket.broadcast.emit('presence:update', {
          user: socket.user,
          status: 'offline',
          timestamp: new Date()
        });
      }
    });

    // ============================================
    // ERROR HANDLING
    // ============================================

    socket.on('error', (error) => {
      console.error('Socket error:', error);
      socket.emit('error', {
        message: 'An error occurred',
        timestamp: new Date()
      });
    });
  });

  return io;
}

/**
 * Emit discussion created event to all connected clients
 */
function emitDiscussionCreated(io, discussion, author) {
  io.emit('discussion:created', {
    discussion,
    author,
    timestamp: new Date()
  });
}

/**
 * Emit discussion updated event to discussion room
 */
function emitDiscussionUpdated(io, discussionId, discussion) {
  io.to(`discussion:${discussionId}`).emit('discussion:updated', {
    discussionId,
    discussion,
    timestamp: new Date()
  });
}

/**
 * Emit discussion deleted event to discussion room
 */
function emitDiscussionDeleted(io, discussionId) {
  io.to(`discussion:${discussionId}`).emit('discussion:deleted', {
    discussionId,
    timestamp: new Date()
  });
}

/**
 * Emit comment added event to discussion room
 */
function emitCommentAdded(io, discussionId, comment, author) {
  io.to(`discussion:${discussionId}`).emit('comment:added', {
    discussionId,
    comment,
    author,
    timestamp: new Date()
  });
}

/**
 * Emit comment updated event to discussion room
 */
function emitCommentUpdated(io, discussionId, commentId, comment) {
  io.to(`discussion:${discussionId}`).emit('comment:updated', {
    discussionId,
    commentId,
    comment,
    timestamp: new Date()
  });
}

/**
 * Emit comment deleted event to discussion room
 */
function emitCommentDeleted(io, discussionId, commentId) {
  io.to(`discussion:${discussionId}`).emit('comment:deleted', {
    discussionId,
    commentId,
    timestamp: new Date()
  });
}

/**
 * Emit like event to discussion room
 */
function emitLikeEvent(io, discussionId, targetId, targetType, action, likeCount, user) {
  const event = targetType === 'discussion' ? 'discussion:like' : 'comment:like';
  io.to(`discussion:${discussionId}`).emit(event, {
    discussionId,
    targetId,
    targetType,
    action,
    likeCount,
    user,
    timestamp: new Date()
  });
}

/**
 * Emit share event to discussion room
 */
function emitShareEvent(io, discussionId, shareCount) {
  io.to(`discussion:${discussionId}`).emit('discussion:share', {
    discussionId,
    shareCount,
    timestamp: new Date()
  });
}

module.exports = {
  initializeSocket,
  emitDiscussionCreated,
  emitDiscussionUpdated,
  emitDiscussionDeleted,
  emitCommentAdded,
  emitCommentUpdated,
  emitCommentDeleted,
  emitLikeEvent,
  emitShareEvent
};


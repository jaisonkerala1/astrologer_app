/**
 * Live Streaming Socket Handler
 * Handles viewer count, comments, gifts, reactions
 */

const EVENTS = require('../events');
const roomManager = require('../roomManager');
const LiveComment = require('../../models/LiveComment');

// Rate limiting: Track user comment timestamps
const userCommentTimestamps = new Map();

// Constants
const MAX_COMMENTS_PER_WINDOW = 3; // Max 3 comments
const RATE_LIMIT_WINDOW = 10000; // Per 10 seconds
const MAX_MESSAGE_LENGTH = 200; // Max 200 characters
const RATE_LIMIT_CLEANUP_INTERVAL = 1800000; // 30 minutes

// Cleanup job: Remove stale rate limit entries every 30 minutes
setInterval(() => {
  const now = Date.now();
  let cleanedCount = 0;
  
  for (const [userId, timestamps] of userCommentTimestamps.entries()) {
    // Remove timestamps older than 30 minutes
    const recentTimestamps = timestamps.filter(t => now - t < RATE_LIMIT_CLEANUP_INTERVAL);
    
    if (recentTimestamps.length === 0) {
      // No recent activity, remove user completely
      userCommentTimestamps.delete(userId);
      cleanedCount++;
    } else if (recentTimestamps.length !== timestamps.length) {
      // Update with cleaned timestamps
      userCommentTimestamps.set(userId, recentTimestamps);
    }
  }
  
  if (cleanedCount > 0) {
    console.log(`🧹 [LIVE] Cleaned ${cleanedCount} stale rate limit entries`);
  }
}, RATE_LIMIT_CLEANUP_INTERVAL);

/**
 * Sanitize comment message
 */
function sanitizeMessage(message) {
  return message
    .trim()
    .replace(/<[^>]*>/g, '') // Remove HTML tags
    .replace(/[^\w\s\u0080-\uFFFF.,!?@#$%&*()\-+='"]/g, '') // Keep basic punctuation + emojis
    .substring(0, MAX_MESSAGE_LENGTH);
}

/**
 * Check if user is rate limited
 */
function isRateLimited(userId) {
  const now = Date.now();
  const timestamps = userCommentTimestamps.get(userId) || [];
  
  // Remove timestamps older than the rate limit window
  const recentTimestamps = timestamps.filter(t => now - t < RATE_LIMIT_WINDOW);
  
  if (recentTimestamps.length >= MAX_COMMENTS_PER_WINDOW) {
    return true; // Rate limited
  }
  
  // Add current timestamp and update
  recentTimestamps.push(now);
  userCommentTimestamps.set(userId, recentTimestamps);
  
  return false; // Not rate limited
}

/**
 * Initialize live streaming socket handlers
 */
function initLiveHandler(io, socket) {
  const user = socket.user;

  /**
   * Broadcaster starts a live stream
   */
  socket.on(EVENTS.LIVE.JOIN, (data) => {
    try {
      const { streamId, isBroadcaster = false, streamTitle = '' } = data;
      
      if (!streamId) {
        socket.emit(EVENTS.ERROR, { message: 'Stream ID required' });
        return;
      }

      const roomId = `${EVENTS.ROOM_PREFIX.LIVE}${streamId}`;
      
      // Create or get room - include likes Set in initial metadata
      const room = roomManager.getOrCreateRoom(roomId, 'live', {
        streamId,
        streamTitle,
        broadcasterId: isBroadcaster ? user.id : null,
        startedAt: new Date(),
        likes: new Set(), // Initialize likes Set when room is created
      });
      
      // Ensure likes Set exists (for rooms created before this update)
      if (!room.metadata.likes) {
        room.metadata.likes = new Set();
      }

      // Join socket room
      socket.join(roomId);
      
      // Add user to room manager
      roomManager.joinRoom(socket.id, roomId, {
        id: user.id,
        name: user.name,
        profileImage: user.profileImage,
        isBroadcaster,
        isAnonymous: user.isAnonymous || false,
      });

      // Get current viewer count (exclude broadcaster)
      const users = roomManager.getRoomUsers(roomId);
      const viewerCount = users.filter(u => !u.isBroadcaster).length;
      const likeCount = room.metadata.likes.size;

      console.log(`📊 [LIVE] Room ${roomId} - Likes: ${likeCount}, Viewers: ${viewerCount}`);

      // Notify everyone in room about new viewer count
      io.to(roomId).emit(EVENTS.LIVE.VIEWER_COUNT, {
        streamId,
        count: viewerCount,
        timestamp: Date.now(),
      });

      // Send current like count to the user who just joined
      socket.emit(EVENTS.LIVE.LIKE_COUNT, {
        streamId,
        count: likeCount,
        timestamp: Date.now(),
      });
      
      console.log(`📤 [LIVE] Sent LIKE_COUNT to ${user.name}: ${likeCount}`);

      // Notify others that a viewer joined (not for broadcaster)
      if (!isBroadcaster) {
        socket.to(roomId).emit(EVENTS.LIVE.VIEWER_JOINED, {
          streamId,
          user: {
            id: user.id,
            name: user.name,
            profileImage: user.profileImage,
          },
          viewerCount,
          timestamp: Date.now(),
        });
      }

      console.log(`📺 [LIVE] ${user.name} joined stream ${streamId} (${isBroadcaster ? 'broadcaster' : 'viewer'}) - ${viewerCount} viewers`);
      
    } catch (error) {
      console.error('❌ [LIVE] Join error:', error);
      socket.emit(EVENTS.ERROR, { message: 'Failed to join stream' });
    }
  });

  /**
   * User leaves live stream
   */
  socket.on(EVENTS.LIVE.LEAVE, (data) => {
    try {
      const { streamId } = data;
      const roomId = `${EVENTS.ROOM_PREFIX.LIVE}${streamId}`;
      
      handleLeaveStream(io, socket, roomId, streamId);
      
    } catch (error) {
      console.error('❌ [LIVE] Leave error:', error);
    }
  });

  /**
   * Send a comment in live stream
   */
  socket.on(EVENTS.LIVE.COMMENT, async (data) => {
    try {
      const { streamId, message } = data;
      
      // Validate input
      if (!streamId || !message) {
        socket.emit(EVENTS.ERROR, { message: 'Stream ID and message required' });
        return;
      }
      
      // Check message length
      if (typeof message !== 'string' || message.trim().length === 0) {
        socket.emit(EVENTS.ERROR, { message: 'Invalid message' });
        return;
      }
      
      if (message.length > MAX_MESSAGE_LENGTH) {
        socket.emit(EVENTS.ERROR, { message: `Message too long (max ${MAX_MESSAGE_LENGTH} characters)` });
        return;
      }

      const roomId = `${EVENTS.ROOM_PREFIX.LIVE}${streamId}`;
      
      // Check if user is in this room
      if (!roomManager.isUserInRoom(socket.id, roomId)) {
        socket.emit(EVENTS.ERROR, { message: 'Not in this stream' });
        return;
      }
      
      // Rate limiting check
      if (isRateLimited(user.id)) {
        socket.emit(EVENTS.ERROR, { 
          message: 'Slow down! You can send up to 3 comments every 10 seconds.',
          rateLimited: true 
        });
        console.log(`⚠️ [LIVE] Rate limited: ${user.name} in ${streamId}`);
        return;
      }
      
      // Sanitize message
      const sanitizedMessage = sanitizeMessage(message);
      
      if (sanitizedMessage.length === 0) {
        socket.emit(EVENTS.ERROR, { message: 'Message contains no valid content' });
        return;
      }

      // Determine user type based on socket user role
      const userType = user.role === 'astrologer' ? 'Astrologer' : 'User';
      
      // Save comment to database for persistence
      const savedComment = await LiveComment.create({
        streamId,
        userId: user.id,
        userType,
        userName: user.name,
        userAvatar: user.profileImage || null,
        message: sanitizedMessage,
        isGift: false,
      });

      // Create comment object for broadcast
      const comment = {
        id: savedComment._id.toString(),
        streamId,
        userId: user.id,
        userName: user.name,
        userAvatar: user.profileImage || null,
        message: sanitizedMessage,
        timestamp: savedComment.createdAt.getTime(),
        isGift: false,
      };

      // Broadcast to all in room (including sender)
      io.to(roomId).emit(EVENTS.LIVE.COMMENT, comment);
      
      console.log(`💬 [LIVE] Comment in ${streamId}: ${user.name}: ${sanitizedMessage.substring(0, 50)}${sanitizedMessage.length > 50 ? '...' : ''}`);
      
    } catch (error) {
      console.error('❌ [LIVE] Comment error:', error);
      socket.emit(EVENTS.ERROR, { message: 'Failed to send comment' });
    }
  });

  /**
   * Send a gift in live stream
   */
  socket.on(EVENTS.LIVE.GIFT, async (data) => {
    try {
      const { streamId, giftType, giftValue = 0 } = data;
      
      if (!streamId || !giftType) {
        socket.emit(EVENTS.ERROR, { message: 'Stream ID and gift type required' });
        return;
      }

      const roomId = `${EVENTS.ROOM_PREFIX.LIVE}${streamId}`;
      
      if (!roomManager.isUserInRoom(socket.id, roomId)) {
        socket.emit(EVENTS.ERROR, { message: 'Not in this stream' });
        return;
      }

      // Determine user type
      const userType = user.role === 'astrologer' ? 'Astrologer' : 'User';
      
      // Save gift as comment to database
      const savedGift = await LiveComment.create({
        streamId,
        userId: user.id,
        userType,
        userName: user.name,
        userAvatar: user.profileImage || null,
        message: `sent a ${giftType}`,
        isGift: true,
        giftType,
        giftValue,
      });

      const gift = {
        id: savedGift._id.toString(),
        streamId,
        senderId: user.id,
        senderName: user.name,
        senderAvatar: user.profileImage || null,
        giftType,
        giftValue,
        timestamp: savedGift.createdAt.getTime(),
      };

      // Broadcast to all in room
      io.to(roomId).emit(EVENTS.LIVE.GIFT, gift);
      
      // Also broadcast as comment for display in comments section
      io.to(roomId).emit(EVENTS.LIVE.COMMENT, {
        id: savedGift._id.toString(),
        streamId,
        userId: user.id,
        userName: user.name,
        userAvatar: user.profileImage || null,
        message: `sent a ${giftType}`,
        timestamp: savedGift.createdAt.getTime(),
        isGift: true,
        giftType,
      });
      
      console.log(`🎁 [LIVE] Gift in ${streamId}: ${user.name} sent ${giftType}`);
      
    } catch (error) {
      console.error('❌ [LIVE] Gift error:', error);
      socket.emit(EVENTS.ERROR, { message: 'Failed to send gift' });
    }
  });

  /**
   * Send a reaction (floating hearts, etc.)
   */
  socket.on(EVENTS.LIVE.REACTION, (data) => {
    try {
      const { streamId, reactionType = 'heart' } = data;
      
      if (!streamId) {
        return;
      }

      const roomId = `${EVENTS.ROOM_PREFIX.LIVE}${streamId}`;
      
      // Broadcast reaction to all (including sender for animation)
      io.to(roomId).emit(EVENTS.LIVE.REACTION, {
        streamId,
        reactionType,
        userId: user.id,
        timestamp: Date.now(),
      });
      
    } catch (error) {
      console.error('❌ [LIVE] Reaction error:', error);
    }
  });

  /**
   * User likes/unlikes a stream
   */
  socket.on(EVENTS.LIVE.LIKE, async (data) => {
    try {
      const { streamId } = data;
      
      console.log(`👍 [LIVE] Like event received from ${user.name} for stream: ${streamId}`);
      
      if (!streamId) {
        socket.emit(EVENTS.ERROR, { message: 'Stream ID required' });
        return;
      }

      const roomId = `${EVENTS.ROOM_PREFIX.LIVE}${streamId}`;
      
      // Check if user is in this room
      if (!roomManager.isUserInRoom(socket.id, roomId)) {
        console.log(`⚠️ [LIVE] User ${user.name} not in room ${roomId}`);
        socket.emit(EVENTS.ERROR, { message: 'Not in this stream' });
        return;
      }

      // Get room and initialize likes if needed
      const room = roomManager.rooms.get(roomId);
      if (!room) {
        console.log(`⚠️ [LIVE] Room not found: ${roomId}`);
        socket.emit(EVENTS.ERROR, { message: 'Stream not found' });
        return;
      }
      
      if (!room.metadata.likes) {
        room.metadata.likes = new Set();
        console.log(`📦 [LIVE] Initialized likes Set for room ${roomId}`);
      }
      
      // Check if user already liked
      if (room.metadata.likes.has(user.id)) {
        console.log(`⚠️ [LIVE] User ${user.name} already liked stream ${streamId}`);
        socket.emit(EVENTS.ERROR, { 
          message: 'Already liked this stream',
          alreadyLiked: true 
        });
        return;
      }
      
      // Add like
      room.metadata.likes.add(user.id);
      const likeCount = room.metadata.likes.size;
      
      console.log(`👍 [LIVE] ${user.name} liked stream ${streamId} - now ${likeCount} total likes`);
      console.log(`👍 [LIVE] Likes Set contents: ${Array.from(room.metadata.likes)}`);
      
      // Broadcast updated like count to all in room
      io.to(roomId).emit(EVENTS.LIVE.LIKE_COUNT, {
        streamId,
        count: likeCount,
        timestamp: Date.now(),
      });
      
      console.log(`📤 [LIVE] Broadcast LIKE_COUNT ${likeCount} to room ${roomId}`);
      
    } catch (error) {
      console.error('❌ [LIVE] Like error:', error);
      socket.emit(EVENTS.ERROR, { message: 'Failed to like stream' });
    }
  });

  /**
   * User unlikes a stream
   */
  socket.on(EVENTS.LIVE.UNLIKE, async (data) => {
    try {
      const { streamId } = data;
      
      if (!streamId) {
        socket.emit(EVENTS.ERROR, { message: 'Stream ID required' });
        return;
      }

      const roomId = `${EVENTS.ROOM_PREFIX.LIVE}${streamId}`;
      
      // Check if user is in this room
      if (!roomManager.isUserInRoom(socket.id, roomId)) {
        socket.emit(EVENTS.ERROR, { message: 'Not in this stream' });
        return;
      }

      // Get room metadata
      const metadata = roomManager.getRoomMetadata(roomId);
      if (!metadata.likes) {
        metadata.likes = new Set();
      }
      
      // Check if user actually liked
      if (!metadata.likes.has(user.id)) {
        return; // Silently ignore if not liked
      }
      
      // Remove like
      metadata.likes.delete(user.id);
      const likeCount = metadata.likes.size;
      
      // Broadcast updated like count to all in room
      io.to(roomId).emit(EVENTS.LIVE.LIKE_COUNT, {
        streamId,
        count: likeCount,
        timestamp: Date.now(),
      });
      
      console.log(`👎 [LIVE] ${user.name} unliked stream ${streamId} - ${likeCount} total likes`);
      
    } catch (error) {
      console.error('❌ [LIVE] Unlike error:', error);
      socket.emit(EVENTS.ERROR, { message: 'Failed to unlike stream' });
    }
  });

  /**
   * Broadcaster ends stream
   */
  socket.on(EVENTS.LIVE.END, (data) => {
    try {
      const { streamId } = data;
      const roomId = `${EVENTS.ROOM_PREFIX.LIVE}${streamId}`;
      
      // Verify broadcaster
      const metadata = roomManager.getRoomMetadata(roomId);
      if (metadata && metadata.broadcasterId !== user.id) {
        socket.emit(EVENTS.ERROR, { message: 'Only broadcaster can end stream' });
        return;
      }

      // Notify all viewers
      io.to(roomId).emit(EVENTS.LIVE.END, {
        streamId,
        message: 'Stream has ended',
        timestamp: Date.now(),
      });

      // Clean up room
      roomManager.deleteRoom(roomId);
      
      console.log(`🛑 [LIVE] Stream ${streamId} ended by broadcaster`);
      
    } catch (error) {
      console.error('❌ [LIVE] End stream error:', error);
    }
  });

  /**
   * Handle disconnect - clean up from all live rooms
   */
  socket.on('disconnect', () => {
    try {
      const leftRooms = roomManager.leaveAllRooms(socket.id);
      
      // Clean up rate limiting data
      userCommentTimestamps.delete(user.id);
      
      for (const { roomId, room } of leftRooms) {
        if (room.type === 'live') {
          const streamId = roomId.replace(EVENTS.ROOM_PREFIX.LIVE, '');
          
          // Get viewer count (exclude broadcaster)
          const users = roomManager.getRoomUsers(roomId);
          const viewerCount = users.filter(u => !u.isBroadcaster).length;
          
          // Notify remaining users
          io.to(roomId).emit(EVENTS.LIVE.VIEWER_COUNT, {
            streamId,
            count: viewerCount,
            timestamp: Date.now(),
          });

          io.to(roomId).emit(EVENTS.LIVE.VIEWER_LEFT, {
            streamId,
            user: { id: user.id, name: user.name },
            viewerCount,
            timestamp: Date.now(),
          });
        }
      }
      
      console.log(`🔌 [SOCKET] ${user.name} disconnected`);
      
    } catch (error) {
      console.error('❌ [SOCKET] Disconnect cleanup error:', error);
    }
  });
}

/**
 * Helper: Handle leaving a stream
 */
function handleLeaveStream(io, socket, roomId, streamId) {
  const user = socket.user;
  
  socket.leave(roomId);
  roomManager.leaveRoom(socket.id, roomId);
  
  // Get viewer count (exclude broadcaster)
  const users = roomManager.getRoomUsers(roomId);
  const viewerCount = users.filter(u => !u.isBroadcaster).length;
  
  // Notify remaining users
  io.to(roomId).emit(EVENTS.LIVE.VIEWER_COUNT, {
    streamId,
    count: viewerCount,
    timestamp: Date.now(),
  });

  io.to(roomId).emit(EVENTS.LIVE.VIEWER_LEFT, {
    streamId,
    user: { id: user.id, name: user.name },
    viewerCount,
    timestamp: Date.now(),
  });
  
  console.log(`👋 [LIVE] ${user.name} left stream ${streamId} - ${viewerCount} viewers`);
}

module.exports = initLiveHandler;


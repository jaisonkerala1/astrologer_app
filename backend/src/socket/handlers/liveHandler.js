/**
 * Live Streaming Socket Handler
 * Handles viewer count, comments, gifts, reactions
 */

const EVENTS = require('../events');
const roomManager = require('../roomManager');

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
      
      // Create or get room
      roomManager.getOrCreateRoom(roomId, 'live', {
        streamId,
        streamTitle,
        broadcasterId: isBroadcaster ? user.id : null,
        startedAt: new Date(),
      });

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

      // Notify everyone in room about new viewer count
      io.to(roomId).emit(EVENTS.LIVE.VIEWER_COUNT, {
        streamId,
        count: viewerCount,
        timestamp: Date.now(),
      });

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
  socket.on(EVENTS.LIVE.COMMENT, (data) => {
    try {
      const { streamId, message } = data;
      
      if (!streamId || !message) {
        socket.emit(EVENTS.ERROR, { message: 'Stream ID and message required' });
        return;
      }

      const roomId = `${EVENTS.ROOM_PREFIX.LIVE}${streamId}`;
      
      // Check if user is in this room
      if (!roomManager.isUserInRoom(socket.id, roomId)) {
        socket.emit(EVENTS.ERROR, { message: 'Not in this stream' });
        return;
      }

      const comment = {
        id: `comment_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        streamId,
        userId: user.id,
        userName: user.name,
        userAvatar: user.profileImage || null,
        message: message.substring(0, 500), // Limit message length
        timestamp: Date.now(),
      };

      // Broadcast to all in room
      io.to(roomId).emit(EVENTS.LIVE.COMMENT, comment);
      
      console.log(`💬 [LIVE] Comment in ${streamId}: ${user.name}: ${message.substring(0, 50)}...`);
      
    } catch (error) {
      console.error('❌ [LIVE] Comment error:', error);
      socket.emit(EVENTS.ERROR, { message: 'Failed to send comment' });
    }
  });

  /**
   * Send a gift in live stream
   */
  socket.on(EVENTS.LIVE.GIFT, (data) => {
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

      const gift = {
        id: `gift_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        streamId,
        senderId: user.id,
        senderName: user.name,
        senderAvatar: user.profileImage || null,
        giftType, // 'heart', 'star', 'diamond', 'crown', 'rainbow'
        giftValue,
        timestamp: Date.now(),
      };

      // Broadcast to all in room
      io.to(roomId).emit(EVENTS.LIVE.GIFT, gift);
      
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
      
      for (const { roomId, room } of leftRooms) {
        if (room.type === 'live') {
          const streamId = roomId.replace(EVENTS.ROOM_PREFIX.LIVE, '');
          const viewerCount = roomManager.getRoomUserCount(roomId);
          
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
  
  const viewerCount = roomManager.getRoomUserCount(roomId);
  
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


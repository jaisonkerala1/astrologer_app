/**
 * Direct Message Handler
 * Handles admin-to-astrologer and user-to-astrologer messaging
 */

const DirectConversation = require('../../models/DirectConversation');
const DirectMessage = require('../../models/DirectMessage');
const { DIRECT_MESSAGE, ROOM_PREFIX } = require('../events');
const FcmService = require('../../services/fcmService');

// Helpers
function getUserContext(socket, fallback = {}) {
  const user = socket.user || {};
  const isAnon = user.isAnonymous || user.role === 'guest';
  
  // Priority: socket.userType (set by optionalSocketAuth) > user.role > fallback
  // If all fail and not anonymous, something is wrong - DON'T default to 'admin'
  let role = socket.userType || user.role || fallback.type;
  if (!role && !isAnon) {
    console.error('⚠️ [DM] getUserContext: No role found for non-anonymous user!', {
      socketUserId: socket.userId,
      socketUserType: socket.userType,
      userRole: user.role,
      userId: user.id,
      isAnon
    });
    role = 'unknown'; // Don't default to admin for authenticated users
  }
  if (isAnon) role = 'admin'; // Anonymous users go to admin support
  if (!role) role = 'admin'; // Final fallback only if completely unidentified
  
  let id = socket.userId || user._id || user.id || fallback.id;
  if (isAnon) id = 'admin';
  if (!id) id = 'admin'; // Final fallback

  return {
    id,
    type: role,
    name: user.name || fallback.name || 'Admin',
    avatar: user.profilePicture || user.avatar || fallback.avatar,
  };
}

function personalRoomFor(userType, userId) {
  if (!userType || !userId) return null;
  const type = String(userType).toLowerCase();
  // Must match src/socket/index.js auto-join logic:
  // Admin joins "admin:" (no suffix)
  if (type === 'admin' && String(userId) === 'admin') {
    return ROOM_PREFIX.ADMIN;
  }
  const prefix = ROOM_PREFIX[String(userType).toUpperCase()];
  if (!prefix) return null;
  return `${prefix}${userId}`;
}

async function ensureConversation(conversationId, participants = [], allowSingleParticipant = false) {
  if (!conversationId) return null;

  const unique = [];
  for (const p of participants) {
    if (!p?.id) continue;
    // Prevent duplicate participants (same id and type)
    if (!unique.some((u) => u.id === p.id && u.type === p.type)) {
      unique.push(p);
    }
  }
  
  let convo = await DirectConversation.findOne({ conversationId });
  
  // If conversation doesn't exist, require 2+ participants to create it
  if (!convo && unique.length < 2) {
    console.error(`❌ [DM] Blocked conversation creation: insufficient participants (${unique.length}) for ${conversationId}`);
    return null;
  }
  
  // If conversation exists, allow adding participants (even if only 1 in array)
  if (!convo) {
    convo = await DirectConversation.create({
      conversationId,
      participants: unique,
      lastMessageAt: new Date(),
    });
  } else {
    let updated = false;
    unique.forEach((p) => {
      if (!convo.participants.some((x) => x.id === p.id)) {
        convo.participants.push(p);
        updated = true;
      }
    });
    if (updated) {
      convo.updatedAt = new Date();
      await convo.save();
    }
  }
  return convo;
}

// Extract a stable user identifier from a socket (best-effort)
function socketUserKey(s) {
  return String(
    s.userId ||
      s.user?._id ||
      s.user?.id ||
      s.user?.userId ||
      s.data?.userId ||
      ''
  );
}

module.exports = (io, socket) => {
  // Join a conversation room
  socket.on(DIRECT_MESSAGE.JOIN, async (data) => {
    try {
      const { conversationId } = data;
      const ctx = getUserContext(socket, { id: data.userId, type: data.userType });
      if (!conversationId) throw new Error('conversationId is required');
      
      // Join the room
      const roomName = `${ROOM_PREFIX.CONVERSATION}${conversationId}`;
      socket.join(roomName);
      
      console.log(`✅ [DM] ${ctx.type} ${ctx.id} joined conversation: ${conversationId}`);
      
      // Add participant to existing conversation (if it exists)
      // Don't create conversation here - it will be created when first message is sent with both participants
      await ensureConversation(conversationId, [
        {
          id: ctx.id,
          type: ctx.type,
          name: ctx.name,
          avatar: ctx.avatar,
        },
      ], true); // allowSingleParticipant = true when joining
      
      // Emit success
      socket.emit('dm:joined', { conversationId, success: true });
      
    } catch (error) {
      console.error('❌ [DM] Error joining conversation:', error);
      socket.emit('error', { message: 'Failed to join conversation', error: error.message });
    }
  });

  // Leave a conversation room
  socket.on(DIRECT_MESSAGE.LEAVE, async (data) => {
    try {
      const { conversationId } = data;
      
      const roomName = `${ROOM_PREFIX.CONVERSATION}${conversationId}`;
      socket.leave(roomName);
      
      console.log(`👋 [DM] User left conversation: ${conversationId}`);
      
    } catch (error) {
      console.error('❌ [DM] Error leaving conversation:', error);
    }
  });

  // Send a direct message
  socket.on(DIRECT_MESSAGE.SEND, async (data) => {
    try {
      const {
        conversationId,
        recipientId,
        recipientType,
        content,
        messageType = 'text',
        mediaUrl,
        mediaSize,
        mediaDuration,
        thumbnailUrl,
        replyToId
      } = data;
      if (!conversationId) throw new Error('conversationId is required');
      if (!recipientId || !recipientType) throw new Error('recipientId and recipientType are required');

      const senderCtx = getUserContext(socket, { id: data.userId, type: data.userType });
      
      // Debug: Log the exact values being used BEFORE validation
      console.log(`🔍 [DM DEBUG] senderCtx.id="${senderCtx.id}", senderCtx.type="${senderCtx.type}", recipientId="${recipientId}", recipientType="${recipientType}", conversationId="${conversationId}"`);
      
      // Prevent self-conversations (sender cannot send to themselves)
      // EXCEPTION: Admin support is always allowed (astrologer → admin)
      const isSelfConversation = String(senderCtx.id) === String(recipientId) && String(senderCtx.type) === String(recipientType);
      const isAdminSupport = String(recipientType).toLowerCase() === 'admin' && String(senderCtx.type).toLowerCase() !== 'admin';
      
      if (isSelfConversation && !isAdminSupport) {
        console.error(`❌ [DM] Blocked self-conversation: ${senderCtx.type}(${senderCtx.id}) cannot send to themselves`);
        socket.emit('error', { message: 'Cannot send message to yourself', error: 'SELF_CONVERSATION_BLOCKED' });
        return;
      }
      
      console.log(
        `📤 [DM] Message from ${senderCtx.type}(${senderCtx.id}) to ${recipientType}(${recipientId}) in conversation ${conversationId}: ${content?.substring(0, 50)}`
      );

      // Ensure conversation exists with both participants
      await ensureConversation(conversationId, [
        { id: senderCtx.id, type: senderCtx.type, name: senderCtx.name, avatar: senderCtx.avatar },
        { id: recipientId, type: recipientType },
      ]);
      
      // Create message in database
      const message = await DirectMessage.create({
        conversationId,
        senderId: senderCtx.id,
        senderType: senderCtx.type,
        senderName: senderCtx.name,
        senderAvatar: senderCtx.avatar,
        recipientId,
        recipientType,
        content,
        messageType,
        mediaUrl,
        mediaSize,
        mediaDuration,
        thumbnailUrl,
        replyToId,
        timestamp: new Date(),
        status: 'sent'
      });
      
      // Update conversation's lastMessage
      await DirectConversation.findOneAndUpdate(
        { conversationId },
        {
          lastMessage: content,
          lastMessageAt: new Date(),
          lastMessageSenderId: senderCtx.id,
          lastMessageSenderType: senderCtx.type,
          updatedAt: new Date()
        },
        { upsert: true }
      );
      
      // Broadcast to other PARTICIPANTS only (skip ALL sockets belonging to the sender user)
      // This prevents the sender from receiving their own message back on duplicate connections.
      const roomName = `${ROOM_PREFIX.CONVERSATION}${conversationId}`;
      console.log(`📡 [DM] Broadcasting to room "${roomName}" (excluding all sockets of ${senderCtx.id})`);

      // Emit manually to each socket in the room except sockets owned by the sender user
      const socketsInRoom = await io.in(roomName).fetchSockets();
      const deliveredPayload = {
        _id: message._id,
        conversationId,
        senderId: senderCtx.id,
        senderType: senderCtx.type,
        senderName: senderCtx.name,
        senderAvatar: senderCtx.avatar,
        recipientId,
        recipientType,
        content,
        messageType,
        mediaUrl,
        mediaSize,
        mediaDuration,
        thumbnailUrl,
        timestamp: message.timestamp,
        status: 'delivered',
        replyToId
      };

      socketsInRoom.forEach((s) => {
        const targetCtx = getUserContext(s, {});
        const targetUserId = socketUserKey(s);
        const isSenderSocket = s.id === socket.id;
        const isSameUser =
          targetUserId && String(targetUserId) === String(senderCtx.id);
        const isSameUserAndType =
          isSameUser &&
          String(targetCtx.type || s.user?.role || s.userType) ===
            String(senderCtx.type);

        console.log(`🔍 [DM BROADCAST] Socket ${s.id}: isSenderSocket=${isSenderSocket}, isSameUser=${isSameUser}, isSameUserAndType=${isSameUserAndType}, targetUserId=${targetUserId}, targetType=${targetCtx.type}`);

        if (!isSenderSocket && !isSameUserAndType) {
          console.log(`✉️ [DM BROADCAST] Emitting to socket ${s.id} (${targetCtx.name})`);
          s.emit(DIRECT_MESSAGE.RECEIVED, deliveredPayload);
        } else {
          console.log(`⏭️ [DM BROADCAST] Skipping socket ${s.id} (sender or same user)`);
        }
      });

      console.log(`✅ [DM] Message delivered to room (excluding sender sockets): ${conversationId}`);

      // Send acknowledgment to sender (so they see their own message once)
      console.log(`📤 [DM] Sending acknowledgment to sender ${senderCtx.id}`);
      socket.emit(DIRECT_MESSAGE.RECEIVED, {
        _id: message._id,
        conversationId,
        senderId: senderCtx.id,
        senderType: senderCtx.type,
        senderName: senderCtx.name,
        senderAvatar: senderCtx.avatar,
        recipientId,
        recipientType,
        content,
        messageType,
        mediaUrl,
        mediaSize,
        mediaDuration,
        thumbnailUrl,
        timestamp: message.timestamp,
        status: 'sent',
        replyToId
      });
      
      // Also emit to recipient's personal room (Socket.IO for foreground)
      const recipientRoom = personalRoomFor(recipientType, recipientId);
      if (recipientRoom) {
        io.to(recipientRoom).emit('dm:new_message', {
          _id: message._id,
          conversationId,
          senderId: senderCtx.id,
          senderType: senderCtx.type,
          senderName: senderCtx.name,
          senderAvatar: senderCtx.avatar,
          content: content.substring(0, 100), // Preview
          timestamp: message.timestamp
        });
      }
      
      console.log(`✅ [DM] Message delivered to room: ${conversationId}`);
      
      // Send FCM push notification (background/locked)
      FcmService.sendMessageNotification(recipientId, recipientType, {
        conversationId,
        senderId: senderCtx.id,
        senderName: senderCtx.name,
        senderType: senderCtx.type,
        content: content || ''
      }).catch(err => {
        console.error('⚠️ [FCM] Failed to send message notification:', err.message);
      });
      
    } catch (error) {
      console.error('❌ [DM] Error sending message:', error);
      socket.emit('error', { message: 'Failed to send message', error: error.message });
    }
  });

  // Typing indicator
  socket.on(DIRECT_MESSAGE.TYPING_START, async (data) => {
    try {
      const { conversationId, userId } = data;
      const userName = socket.user?.name || socket.userName || 'User';
      
      const roomName = `${ROOM_PREFIX.CONVERSATION}${conversationId}`;
      
      // Broadcast to others in the room (not to sender)
      socket.to(roomName).emit(DIRECT_MESSAGE.TYPING_START, { 
        conversationId, 
        userId,
        userName
      });
      
    } catch (error) {
      console.error('❌ [DM] Error sending typing indicator:', error);
    }
  });

  // Stop typing
  socket.on(DIRECT_MESSAGE.TYPING_STOP, async (data) => {
    try {
      const { conversationId, userId } = data;
      
      const roomName = `${ROOM_PREFIX.CONVERSATION}${conversationId}`;
      socket.to(roomName).emit(DIRECT_MESSAGE.TYPING_STOP, { 
        conversationId, 
        userId 
      });
      
    } catch (error) {
      console.error('❌ [DM] Error sending stop typing:', error);
    }
  });

  // Mark messages as read
  socket.on(DIRECT_MESSAGE.MARK_READ, async (data) => {
    try {
      const { conversationId, messageIds } = data;
      const readerId = socket.userId || socket.user?._id || socket.user?.id;
      
      // Update messages as read
      const result = await DirectMessage.updateMany(
        { 
          _id: { $in: messageIds },
          status: { $ne: 'read' }
        },
        { 
          status: 'read', 
          readAt: new Date() 
        }
      );
      
      console.log(`✅ [DM] Marked ${result.modifiedCount} messages as read in ${conversationId}`);
      
      // Notify sender that messages were read
      const roomName = `${ROOM_PREFIX.CONVERSATION}${conversationId}`;
      socket.to(roomName).emit('dm:messages_read', {
        conversationId,
        messageIds,
        readBy: readerId,
        readAt: new Date()
      });
      
    } catch (error) {
      console.error('❌ [DM] Error marking messages as read:', error);
    }
  });

  // Request message history
  socket.on(DIRECT_MESSAGE.HISTORY, async (data) => {
    try {
      const { conversationId, page = 1, limit = 50 } = data;
      if (!conversationId) throw new Error('conversationId is required');
      
      const skip = (page - 1) * limit;
      
      // Get messages from database
      const messages = await DirectMessage.find({ 
        conversationId,
        isDeleted: false
      })
        .sort({ timestamp: -1 })
        .skip(skip)
        .limit(limit)
        .lean();
      
      const total = await DirectMessage.countDocuments({ 
        conversationId,
        isDeleted: false
      });
      
      // Send history back to requesting client
      socket.emit(DIRECT_MESSAGE.HISTORY, {
        conversationId,
        messages: messages.reverse(), // Oldest first
        total,
        page,
        limit,
        hasMore: total > (page * limit)
      });
      
      console.log(`✅ [DM] Sent ${messages.length}/${total} messages for conversation: ${conversationId} (page ${page})`);
      
    } catch (error) {
      console.error('❌ [DM] Error loading message history:', error);
      socket.emit('error', { message: 'Failed to load messages', error: error.message });
    }
  });
};



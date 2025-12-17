/**
 * Direct Message Handler
 * Handles admin-to-astrologer and user-to-astrologer messaging
 */

const DirectConversation = require('../../models/DirectConversation');
const DirectMessage = require('../../models/DirectMessage');
const { DIRECT_MESSAGE, ROOM_PREFIX } = require('../events');

module.exports = (io, socket) => {
  // Join a conversation room
  socket.on(DIRECT_MESSAGE.JOIN, async (data) => {
    try {
      const { conversationId, userId, userType } = data;
      
      // Join the room
      const roomName = `${ROOM_PREFIX.CONVERSATION}${conversationId}`;
      socket.join(roomName);
      
      console.log(`✅ [DM] ${userType} ${userId} joined conversation: ${conversationId}`);
      
      // Find or create conversation
      let conversation = await DirectConversation.findOne({ conversationId });
      
      if (!conversation) {
        // Create new conversation
        conversation = await DirectConversation.create({
          conversationId,
          participants: [{
            id: userId,
            type: userType,
            name: socket.user?.name || userId,
            avatar: socket.user?.profilePicture || socket.user?.avatar
          }],
          lastMessageAt: new Date()
        });
        console.log(`✨ [DM] Created new conversation: ${conversationId}`);
      } else {
        // Add participant if not exists
        const participantExists = conversation.participants.some(p => p.id === userId);
        if (!participantExists) {
          conversation.participants.push({
            id: userId,
            type: userType,
            name: socket.user?.name || userId,
            avatar: socket.user?.profilePicture || socket.user?.avatar
          });
          await conversation.save();
        }
      }
      
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
      
      const senderId = socket.userId || socket.user?._id || socket.user?.id || 'admin';
      const senderType = socket.userType || socket.user?.role || 'astrologer';
      const senderName = socket.user?.name || socket.userName || 'Admin';
      const senderAvatar = socket.user?.profilePicture || socket.user?.avatar || socket.userAvatar;
      
      console.log(`📤 [DM] Message from ${senderType}(${senderId}) to ${recipientType}(${recipientId}): ${content?.substring(0, 50)}`);
      
      // Create message in database
      const message = await DirectMessage.create({
        conversationId,
        senderId,
        senderType,
        senderName,
        senderAvatar,
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
          lastMessageSenderId: senderId,
          lastMessageSenderType: senderType,
          updatedAt: new Date()
        },
        { upsert: true }
      );
      
      // Broadcast to everyone in the conversation room
      const roomName = `${ROOM_PREFIX.CONVERSATION}${conversationId}`;
      io.to(roomName).emit(DIRECT_MESSAGE.RECEIVED, {
        id: message._id,
        conversationId,
        senderId,
        senderType,
        senderName,
        senderAvatar,
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
      });
      
      // Also emit to recipient's personal room (for push notifications)
      const recipientRoom = `${ROOM_PREFIX[recipientType.toUpperCase()]}${recipientId}`;
      io.to(recipientRoom).emit('dm:new_message', {
        conversationId,
        senderId,
        senderType,
        senderName,
        senderAvatar,
        content: content.substring(0, 100), // Preview
        timestamp: message.timestamp
      });
      
      console.log(`✅ [DM] Message delivered to room: ${conversationId}`);
      
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


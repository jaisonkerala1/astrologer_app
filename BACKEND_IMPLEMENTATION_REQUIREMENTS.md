# 🔧 Backend Implementation Requirements

## For Admin ↔ Astrologer & User ↔ Astrologer Communication

---

## 📋 Overview

The Flutter frontend has been **fully refactored** to support generic communication. Now we need backend implementation to make it functional.

---

## 🗄️ Database Models Required

### **1. DirectConversation Model**

```javascript
// backend/src/models/DirectConversation.js
const directConversationSchema = new mongoose.Schema({
  // Participants
  participants: [{
    id: String,
    type: {
      type: String,
      enum: ['user', 'astrologer', 'admin'],
      required: true
    },
    name: String,
    profilePicture: String,
    joinedAt: {
      type: Date,
      default: Date.now
    }
  }],
  
  // Conversation type
  conversationType: {
    type: String,
    enum: ['admin_astrologer', 'user_astrologer', 'group'],
    required: true
  },
  
  // Last message info
  lastMessage: {
    content: String,
    senderId: String,
    timestamp: Date,
    messageType: String
  },
  
  // Status
  isActive: {
    type: Boolean,
    default: true
  },
  
  // Unread counts per participant
  unreadCount: {
    type: Map,
    of: Number,
    default: {}
  },
  
  // Context (link to consultation, service request, etc.)
  contextType: {
    type: String,
    enum: ['consultation', 'service_request', 'support', 'general'],
    default: 'general'
  },
  contextId: mongoose.Schema.Types.ObjectId,
}, {
  timestamps: true
});
```

### **2. DirectMessage Model**

```javascript
// backend/src/models/DirectMessage.js
const directMessageSchema = new mongoose.Schema({
  conversationId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'DirectConversation',
    required: true,
    index: true
  },
  
  senderId: {
    type: String,
    required: true
  },
  senderType: {
    type: String,
    enum: ['user', 'astrologer', 'admin'],
    required: true
  },
  
  recipientId: {
    type: String,
    required: true
  },
  recipientType: {
    type: String,
    enum: ['user', 'astrologer', 'admin'],
    required: true
  },
  
  messageType: {
    type: String,
    enum: ['text', 'image', 'audio', 'file', 'system'],
    default: 'text'
  },
  content: {
    type: String,
    required: true
  },
  mediaUrl: String,
  
  // Status tracking
  status: {
    type: String,
    enum: ['sent', 'delivered', 'read', 'failed'],
    default: 'sent'
  },
  readAt: Date,
  deliveredAt: Date,
  
  // Reply reference
  replyTo: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'DirectMessage'
  },
  
  isDeleted: {
    type: Boolean,
    default: false
  },
  deletedBy: [String],
}, {
  timestamps: true
});

// Indexes
directMessageSchema.index({ conversationId: 1, createdAt: -1 });
directMessageSchema.index({ senderId: 1 });
directMessageSchema.index({ recipientId: 1 });
```

### **3. Call Model**

```javascript
// backend/src/models/Call.js
const callSchema = new mongoose.Schema({
  // Participants
  callerId: {
    type: String,
    required: true
  },
  callerType: {
    type: String,
    enum: ['user', 'astrologer', 'admin'],
    required: true
  },
  calleeId: {
    type: String,
    required: true
  },
  calleeType: {
    type: String,
    enum: ['user', 'astrologer', 'admin'],
    required: true
  },
  
  // Call details
  callType: {
    type: String,
    enum: ['voice', 'video'],
    required: true
  },
  status: {
    type: String,
    enum: ['initiated', 'ringing', 'answered', 'ongoing', 'ended', 'rejected', 'missed', 'failed'],
    default: 'initiated'
  },
  
  // Agora integration
  agoraChannelName: {
    type: String,
    required: true
  },
  agoraToken: String,
  agoraUid: Number,
  
  // Timing
  initiatedAt: {
    type: Date,
    default: Date.now
  },
  answeredAt: Date,
  endedAt: Date,
  duration: Number, // in seconds
  
  // End reason
  endReason: {
    type: String,
    enum: ['completed', 'rejected', 'no_answer', 'network_error', 'cancelled']
  },
  endedBy: String,
  
  // Context
  conversationId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'DirectConversation'
  },
  consultationId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Consultation'
  },
}, {
  timestamps: true
});
```

---

## 🛣️ API Endpoints to Create

### **Admin Conversation Endpoints**

```javascript
// backend/src/routes/admin.js

/**
 * Get admin conversation with specific astrologer
 * GET /api/admin/conversations/:astrologerId
 */
router.get('/conversations/:astrologerId', adminAuth, async (req, res) => {
  // Get or create conversation between admin and astrologer
  // Return conversation with recent messages
});

/**
 * Get messages in admin conversation
 * GET /api/admin/conversations/:astrologerId/messages
 */
router.get('/conversations/:astrologerId/messages', adminAuth, async (req, res) => {
  // Return paginated messages
});

/**
 * Send message to astrologer
 * POST /api/admin/conversations/:astrologerId/messages
 */
router.post('/conversations/:astrologerId/messages', adminAuth, async (req, res) => {
  // Save message
  // Emit via Socket.IO
});

/**
 * Initiate call to astrologer
 * POST /api/admin/calls/initiate
 */
router.post('/calls/initiate', adminAuth, async (req, res) => {
  // Create call record
  // Generate Agora token
  // Emit via Socket.IO to astrologer
});
```

### **Astrologer Conversation Endpoints**

```javascript
// backend/src/routes/conversation.js (NEW FILE)

/**
 * Get admin conversation (for astrologer)
 * GET /api/conversations/admin
 */
router.get('/admin', auth, async (req, res) => {
  // Return conversation with admin
  // Include unread count
});

/**
 * Get admin messages (for astrologer)
 * GET /api/conversations/admin/messages
 */
router.get('/admin/messages', auth, async (req, res) => {
  // Return messages with admin
});

/**
 * Send message to admin (for astrologer)
 * POST /api/conversations/admin/messages
 */
router.post('/admin/messages', auth, async (req, res) => {
  // Save message
  // Emit via Socket.IO
});

/**
 * Get conversation by ID
 * GET /api/conversations/:id
 */
router.get('/:id', auth, async (req, res) => {
  // Return conversation
});

/**
 * Get messages in conversation
 * GET /api/conversations/:id/messages
 */
router.get('/:id/messages', auth, async (req, res) => {
  // Return paginated messages
});

/**
 * Send message in conversation
 * POST /api/conversations/:id/messages
 */
router.post('/:id/messages', auth, async (req, res) => {
  // Save message
  // Emit via Socket.IO
});
```

### **Call Endpoints**

```javascript
// backend/src/routes/calls.js (NEW FILE)

/**
 * Generate Agora token for admin call
 * POST /api/calls/admin/token
 */
router.post('/admin/token', adminAuth, async (req, res) => {
  // Generate Agora token
  // Return channel name and token
});

/**
 * Initiate call
 * POST /api/calls/initiate
 */
router.post('/initiate', auth, async (req, res) => {
  // Create call record
  // Generate Agora token
  // Emit via Socket.IO
});

/**
 * End call
 * POST /api/calls/:id/end
 */
router.post('/:id/end', auth, async (req, res) => {
  // Update call status
  // Calculate duration
  // Notify other party via Socket.IO
});

/**
 * Get call history
 * GET /api/calls/history
 */
router.get('/history', auth, async (req, res) => {
  // Return paginated call history
});
```

---

## 🔌 Socket.IO Handlers to Create

### **New File: `backend/src/socket/handlers/directMessageHandler.js`**

```javascript
module.exports = function initDirectMessageHandler(socket, io, roomManager) {
  
  // Join conversation room
  socket.on('dm:join_conversation', async ({ conversationId, userId, userType }) => {
    console.log(`📨 User ${userId} joining conversation ${conversationId}`);
    
    // Join Socket.IO room
    socket.join(`conversation:${conversationId}`);
    
    // Track in room manager
    roomManager.joinRoom(socket.id, `conversation:${conversationId}`, {
      userId,
      userType,
      conversationId
    });
    
    // Send confirmation
    socket.emit('dm:joined', { conversationId });
  });
  
  // Send message
  socket.on('dm:send_message', async (data) => {
    const { conversationId, recipientId, recipientType, content, messageType } = data;
    
    console.log(`📩 Message sent to conversation ${conversationId}`);
    
    try {
      // Save message to database
      const message = await DirectMessage.create({
        conversationId,
        senderId: socket.user.id,
        senderType: socket.user.type,
        recipientId,
        recipientType,
        content,
        messageType: messageType || 'text',
        status: 'sent'
      });
      
      // Update conversation last message
      await DirectConversation.findByIdAndUpdate(conversationId, {
        lastMessage: {
          content,
          senderId: socket.user.id,
          timestamp: new Date(),
          messageType: messageType || 'text'
        },
        $inc: {
          [`unreadCount.${recipientId}`]: 1
        }
      });
      
      // Emit to conversation room
      io.to(`conversation:${conversationId}`).emit('dm:message_received', {
        ...message.toObject(),
        conversationId
      });
      
      // Send push notification if recipient offline
      // ... (implementation depends on your push notification service)
      
    } catch (error) {
      console.error('Error sending message:', error);
      socket.emit('dm:error', { message: 'Failed to send message' });
    }
  });
  
  // Typing indicators
  socket.on('dm:typing_start', ({ conversationId, userId }) => {
    socket.to(`conversation:${conversationId}`).emit('dm:typing_start', {
      conversationId,
      userId
    });
  });
  
  socket.on('dm:typing_stop', ({ conversationId, userId }) => {
    socket.to(`conversation:${conversationId}`).emit('dm:typing_stop', {
      conversationId,
      userId
    });
  });
  
  // Mark messages as read
  socket.on('dm:mark_read', async ({ conversationId, messageIds }) => {
    try {
      // Update message status
      await DirectMessage.updateMany(
        {
          _id: { $in: messageIds },
          recipientId: socket.user.id
        },
        {
          status: 'read',
          readAt: new Date()
        }
      );
      
      // Update unread count
      await DirectConversation.findByIdAndUpdate(conversationId, {
        $set: {
          [`unreadCount.${socket.user.id}`]: 0
        }
      });
      
      // Notify sender
      io.to(`conversation:${conversationId}`).emit('dm:messages_read', {
        conversationId,
        messageIds,
        readBy: socket.user.id
      });
      
    } catch (error) {
      console.error('Error marking messages as read:', error);
    }
  });
  
  // Leave conversation
  socket.on('dm:leave_conversation', ({ conversationId }) => {
    socket.leave(`conversation:${conversationId}`);
    roomManager.leaveRoom(socket.id, `conversation:${conversationId}`);
  });
};
```

### **New File: `backend/src/socket/handlers/callHandler.js`**

```javascript
const { RtcTokenBuilder, RtcRole } = require('agora-token');
const Call = require('../../models/Call');

module.exports = function initCallHandler(socket, io, roomManager) {
  
  // Initiate call
  socket.on('call:initiate', async ({ calleeId, calleeType, callType }) => {
    console.log(`📞 Call initiated: ${socket.user.id} -> ${calleeId}`);
    
    try {
      // Generate Agora credentials
      const channelName = `call_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      const appId = process.env.AGORA_APP_ID;
      const appCertificate = process.env.AGORA_APP_CERTIFICATE;
      const uid = 0;
      const role = RtcRole.PUBLISHER;
      const expirationTimeInSeconds = 3600;
      const currentTimestamp = Math.floor(Date.now() / 1000);
      const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;
      
      const token = RtcTokenBuilder.buildTokenWithUid(
        appId,
        appCertificate,
        channelName,
        uid,
        role,
        privilegeExpiredTs
      );
      
      // Create call record
      const call = await Call.create({
        callerId: socket.user.id,
        callerType: socket.user.type,
        calleeId,
        calleeType,
        callType,
        status: 'initiated',
        agoraChannelName: channelName,
        agoraToken: token,
        agoraUid: uid
      });
      
      // Emit to callee
      io.to(`user:${calleeId}`).emit('call:incoming', {
        callId: call._id.toString(),
        callerId: socket.user.id,
        callerType: socket.user.type,
        callerName: socket.user.name,
        callerPhone: socket.user.phone,
        callerAvatar: socket.user.profilePicture,
        callType,
        agoraToken: token,
        channelName
      });
      
      // Send back to caller
      socket.emit('call:initiated', {
        callId: call._id.toString(),
        channelName,
        agoraToken: token
      });
      
      // Set timeout for no answer
      setTimeout(async () => {
        const currentCall = await Call.findById(call._id);
        if (currentCall && currentCall.status === 'initiated') {
          currentCall.status = 'missed';
          currentCall.endReason = 'no_answer';
          currentCall.endedAt = new Date();
          await currentCall.save();
          
          io.to(`user:${calleeId}`).emit('call:missed', {
            callId: call._id.toString()
          });
        }
      }, 60000); // 60 seconds timeout
      
    } catch (error) {
      console.error('Error initiating call:', error);
      socket.emit('call:error', { message: 'Failed to initiate call' });
    }
  });
  
  // Accept call
  socket.on('call:accept', async ({ callId }) => {
    console.log(`✅ Call accepted: ${callId}`);
    
    try {
      const call = await Call.findById(callId);
      if (!call) {
        return socket.emit('call:error', { message: 'Call not found' });
      }
      
      call.status = 'answered';
      call.answeredAt = new Date();
      await call.save();
      
      // Notify caller
      io.to(`user:${call.callerId}`).emit('call:accepted', {
        callId: call._id.toString()
      });
      
    } catch (error) {
      console.error('Error accepting call:', error);
      socket.emit('call:error', { message: 'Failed to accept call' });
    }
  });
  
  // Reject call
  socket.on('call:reject', async ({ callId, reason }) => {
    console.log(`❌ Call rejected: ${callId}`);
    
    try {
      const call = await Call.findById(callId);
      if (!call) return;
      
      call.status = 'rejected';
      call.endReason = reason || 'declined';
      call.endedAt = new Date();
      call.endedBy = socket.user.id;
      await call.save();
      
      // Notify caller
      io.to(`user:${call.callerId}`).emit('call:rejected', {
        callId: call._id.toString(),
        reason
      });
      
    } catch (error) {
      console.error('Error rejecting call:', error);
    }
  });
  
  // End call
  socket.on('call:end', async ({ callId, duration }) => {
    console.log(`🔚 Call ended: ${callId}`);
    
    try {
      const call = await Call.findById(callId);
      if (!call) return;
      
      call.status = 'ended';
      call.endReason = 'completed';
      call.endedAt = new Date();
      call.endedBy = socket.user.id;
      call.duration = duration;
      await call.save();
      
      // Notify other party
      const otherUserId = call.callerId === socket.user.id 
        ? call.calleeId 
        : call.callerId;
      
      io.to(`user:${otherUserId}`).emit('call:ended', {
        callId: call._id.toString(),
        duration
      });
      
    } catch (error) {
      console.error('Error ending call:', error);
    }
  });
};
```

### **Update: `backend/src/socket/index.js`**

```javascript
const { initDirectMessageHandler } = require('./handlers/directMessageHandler');
const { initCallHandler } = require('./handlers/callHandler');

// In initSocketIO function, add:
initDirectMessageHandler(socket, io, roomManager);
initCallHandler(socket, io, roomManager);
```

---

## 🔒 Security & Best Practices

1. **Authentication:**
   - Validate all Socket.IO connections
   - Check JWT tokens
   - Verify user permissions

2. **Authorization:**
   - Admin can message any astrologer
   - Astrologer can only reply to admin or their own users
   - Users can only message astrologers they've consulted

3. **Rate Limiting:**
   - Limit messages per minute (e.g., 10 messages/min)
   - Limit call initiations (e.g., 5 calls/hour)

4. **Data Validation:**
   - Sanitize message content
   - Validate message types
   - Check file uploads

---

## ✅ Implementation Checklist

- [ ] Create DirectConversation model
- [ ] Create DirectMessage model
- [ ] Create Call model
- [ ] Implement admin conversation endpoints
- [ ] Implement astrologer conversation endpoints
- [ ] Implement call endpoints
- [ ] Create directMessageHandler
- [ ] Create callHandler
- [ ] Update socket/index.js
- [ ] Add authentication middleware
- [ ] Add rate limiting
- [ ] Test admin-to-astrologer messaging
- [ ] Test admin-to-astrologer calling
- [ ] Test real-time message delivery
- [ ] Test call flow end-to-end

---

## 🚀 Ready to Deploy!

Once backend is implemented, the Flutter app will have:
- ✅ Real-time admin messaging
- ✅ Admin voice/video calls
- ✅ Extensible for user communication
- ✅ Full Socket.IO integration
- ✅ Agora video/audio support

**All frontend code is ready and waiting!** 🎉

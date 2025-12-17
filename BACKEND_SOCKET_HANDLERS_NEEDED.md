# 🔧 Backend Socket.IO Handlers Required

## ⚠️ What Needs to Be Implemented

Your Flutter app now uses **Socket.IO ONLY** for communication. Here's what your backend needs to handle:

---

## 📂 File Structure

```
backend/src/socket/
├── index.js              # ✅ Already exists
├── events.js             # ✅ Updated with new events
├── handlers/
│   ├── liveHandler.js    # ✅ Already exists  
│   ├── chatHandler.js    # ✅ Already exists
│   ├── directMessageHandler.js  # ❌ CREATE THIS
│   └── callHandler.js    # ❌ CREATE THIS
```

---

## 1️⃣ Create `directMessageHandler.js`

```javascript
// backend/src/socket/handlers/directMessageHandler.js

const DirectConversation = require('../../models/DirectConversation');
const DirectMessage = require('../../models/DirectMessage');
const { DIRECT_MESSAGE, ROOM_PREFIX } = require('../events');

module.exports = (io, socket) => {
  // Join a conversation room
  socket.on(DIRECT_MESSAGE.JOIN, async (data) => {
    try {
      const { conversationId, userId, userType } = data;
      
      // Join the room
      socket.join(`${ROOM_PREFIX.CONVERSATION}${conversationId}`);
      
      console.log(`✅ [DM] ${userType} ${userId} joined conversation: ${conversationId}`);
      
      // Optionally update "last seen"
      // await updateLastSeen(conversationId, userId);
      
    } catch (error) {
      console.error('❌ [DM] Error joining conversation:', error);
      socket.emit('error', { message: 'Failed to join conversation' });
    }
  });

  // Leave a conversation room
  socket.on(DIRECT_MESSAGE.LEAVE, async (data) => {
    try {
      const { conversationId } = data;
      
      socket.leave(`${ROOM_PREFIX.CONVERSATION}${conversationId}`);
      
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
        mediaUrl
      } = data;
      
      const senderId = socket.userId;
      const senderType = socket.userType || 'astrologer';
      
      console.log(`📤 [DM] Message from ${senderType} to ${recipientType}: ${content}`);
      
      // Create message in database
      const message = await DirectMessage.create({
        conversationId,
        senderId,
        senderType,
        recipientId,
        recipientType,
        content,
        messageType,
        mediaUrl,
        timestamp: new Date(),
        status: 'sent'
      });
      
      // Update conversation's lastMessage
      await DirectConversation.findByIdAndUpdate(conversationId, {
        lastMessage: content,
        lastMessageAt: new Date()
      });
      
      // Broadcast to everyone in the conversation room
      io.to(`${ROOM_PREFIX.CONVERSATION}${conversationId}`).emit(
        DIRECT_MESSAGE.RECEIVED,
        {
          id: message._id,
          conversationId,
          senderId,
          senderType,
          content,
          messageType,
          mediaUrl,
          timestamp: message.timestamp,
          status: 'delivered'
        }
      );
      
      // Send push notification to recipient (if offline)
      // await sendPushNotification(recipientId, recipientType, {
      //   title: `New message from ${senderType}`,
      //   body: content
      // });
      
      console.log(`✅ [DM] Message delivered to room: ${conversationId}`);
      
    } catch (error) {
      console.error('❌ [DM] Error sending message:', error);
      socket.emit('error', { message: 'Failed to send message' });
    }
  });

  // Typing indicator
  socket.on(DIRECT_MESSAGE.TYPING_START, async (data) => {
    try {
      const { conversationId, userId } = data;
      
      // Broadcast to others in the room
      socket.to(`${ROOM_PREFIX.CONVERSATION}${conversationId}`).emit(
        DIRECT_MESSAGE.TYPING_START,
        { conversationId, userId }
      );
      
    } catch (error) {
      console.error('❌ [DM] Error sending typing indicator:', error);
    }
  });

  // Stop typing
  socket.on(DIRECT_MESSAGE.TYPING_STOP, async (data) => {
    try {
      const { conversationId, userId } = data;
      
      socket.to(`${ROOM_PREFIX.CONVERSATION}${conversationId}`).emit(
        DIRECT_MESSAGE.TYPING_STOP,
        { conversationId, userId }
      );
      
    } catch (error) {
      console.error('❌ [DM] Error sending stop typing:', error);
    }
  });

  // Mark messages as read
  socket.on(DIRECT_MESSAGE.MARK_READ, async (data) => {
    try {
      const { conversationId, messageIds } = data;
      
      // Update messages as read
      await DirectMessage.updateMany(
        { _id: { $in: messageIds } },
        { status: 'read', readAt: new Date() }
      );
      
      console.log(`✅ [DM] Marked ${messageIds.length} messages as read`);
      
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
      const messages = await DirectMessage.find({ conversationId })
        .sort({ timestamp: -1 })
        .skip(skip)
        .limit(limit)
        .lean();
      
      const total = await DirectMessage.countDocuments({ conversationId });
      
      // Send history back to requesting client
      socket.emit(DIRECT_MESSAGE.HISTORY, {
        conversationId,
        messages: messages.reverse(), // Oldest first
        total,
        page,
        limit
      });
      
      console.log(`✅ [DM] Sent ${messages.length} messages for conversation: ${conversationId}`);
      
    } catch (error) {
      console.error('❌ [DM] Error loading message history:', error);
      socket.emit('error', { message: 'Failed to load messages' });
    }
  });
};
```

---

## 2️⃣ Create `callHandler.js`

```javascript
// backend/src/socket/handlers/callHandler.js

const { RtcTokenBuilder, RtcRole } = require('agora-access-token');
const Call = require('../../models/Call');
const { CALL, ROOM_PREFIX } = require('../events');

// Agora config (from .env)
const AGORA_APP_ID = process.env.AGORA_APP_ID;
const AGORA_APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE;

module.exports = (io, socket) => {
  // Initiate a call
  socket.on(CALL.INITIATE, async (data) => {
    try {
      const {
        recipientId,
        recipientType,
        callType,
        channelName
      } = data;
      
      const callerId = socket.userId;
      const callerType = socket.userType || 'astrologer';
      
      console.log(`📞 [CALL] ${callerType} initiating ${callType} call to ${recipientType}`);
      
      // Generate Agora token
      const uid = 0; // 0 for auto-generated
      const role = RtcRole.PUBLISHER;
      const expirationTimeInSeconds = 3600; // 1 hour
      const currentTimestamp = Math.floor(Date.now() / 1000);
      const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;
      
      const agoraToken = RtcTokenBuilder.buildTokenWithUid(
        AGORA_APP_ID,
        AGORA_APP_CERTIFICATE,
        channelName,
        uid,
        role,
        privilegeExpiredTs
      );
      
      // Create call record
      const call = await Call.create({
        callerId,
        callerType,
        recipientId,
        recipientType,
        callType,
        channelName,
        agoraToken,
        status: 'initiated',
        startedAt: new Date()
      });
      
      // Send token back to caller
      socket.emit(CALL.TOKEN, {
        callId: call._id,
        agoraToken,
        channelName,
        uid
      });
      
      // Notify recipient
      const recipientRoom = `${ROOM_PREFIX.ASTROLOGER}${recipientId}`;
      io.to(recipientRoom).emit(CALL.INCOMING, {
        callId: call._id,
        callerId,
        callerName: socket.userName || 'Admin',
        callerType,
        callType,
        agoraToken,
        channelName,
        callerAvatar: socket.userAvatar || ''
      });
      
      console.log(`✅ [CALL] Call initiated: ${call._id}`);
      
    } catch (error) {
      console.error('❌ [CALL] Error initiating call:', error);
      socket.emit('error', { message: 'Failed to initiate call' });
    }
  });

  // Accept a call
  socket.on(CALL.ACCEPT, async (data) => {
    try {
      const { callId, contactId } = data;
      
      // Update call status
      await Call.findByIdAndUpdate(callId, {
        status: 'accepted',
        acceptedAt: new Date()
      });
      
      // Notify caller
      const callerRoom = `${ROOM_PREFIX.ASTROLOGER}${contactId}`;
      io.to(callerRoom).emit(CALL.ACCEPT, {
        callId,
        contactId: socket.userId
      });
      
      console.log(`✅ [CALL] Call accepted: ${callId}`);
      
    } catch (error) {
      console.error('❌ [CALL] Error accepting call:', error);
    }
  });

  // Reject a call
  socket.on(CALL.REJECT, async (data) => {
    try {
      const { callId, contactId, reason } = data;
      
      // Update call status
      await Call.findByIdAndUpdate(callId, {
        status: 'rejected',
        endedAt: new Date(),
        endReason: reason || 'declined'
      });
      
      // Notify caller
      const callerRoom = `${ROOM_PREFIX.ASTROLOGER}${contactId}`;
      io.to(callerRoom).emit(CALL.REJECT, {
        callId,
        contactId: socket.userId,
        reason
      });
      
      console.log(`❌ [CALL] Call rejected: ${callId}`);
      
    } catch (error) {
      console.error('❌ [CALL] Error rejecting call:', error);
    }
  });

  // Call connected
  socket.on(CALL.CONNECTED, async (data) => {
    try {
      const { callId, contactId } = data;
      
      // Update call status
      await Call.findByIdAndUpdate(callId, {
        status: 'connected',
        connectedAt: new Date()
      });
      
      console.log(`🔗 [CALL] Call connected: ${callId}`);
      
    } catch (error) {
      console.error('❌ [CALL] Error updating call status:', error);
    }
  });

  // End call
  socket.on(CALL.END, async (data) => {
    try {
      const { callId, contactId, duration } = data;
      
      // Update call record
      await Call.findByIdAndUpdate(callId, {
        status: 'ended',
        endedAt: new Date(),
        duration: duration || 0,
        endReason: 'completed'
      });
      
      // Notify other party
      const recipientRoom = `${ROOM_PREFIX.ASTROLOGER}${contactId}`;
      io.to(recipientRoom).emit(CALL.END, {
        callId,
        duration
      });
      
      console.log(`📴 [CALL] Call ended: ${callId} (duration: ${duration}s)`);
      
    } catch (error) {
      console.error('❌ [CALL] Error ending call:', error);
    }
  });

  // Request token (if needed during call)
  socket.on(CALL.TOKEN, async (data) => {
    try {
      const { callId, channelName } = data;
      
      // Generate new token
      const uid = 0;
      const role = RtcRole.PUBLISHER;
      const expirationTimeInSeconds = 3600;
      const currentTimestamp = Math.floor(Date.now() / 1000);
      const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;
      
      const agoraToken = RtcTokenBuilder.buildTokenWithUid(
        AGORA_APP_ID,
        AGORA_APP_CERTIFICATE,
        channelName,
        uid,
        role,
        privilegeExpiredTs
      );
      
      socket.emit(CALL.TOKEN, {
        callId,
        agoraToken,
        channelName,
        uid
      });
      
      console.log(`🔑 [CALL] New token generated for call: ${callId}`);
      
    } catch (error) {
      console.error('❌ [CALL] Error generating token:', error);
      socket.emit('error', { message: 'Failed to generate token' });
    }
  });
};
```

---

## 3️⃣ Update `socket/index.js`

```javascript
// backend/src/socket/index.js

const liveHandler = require('./handlers/liveHandler');
const chatHandler = require('./handlers/chatHandler');
const directMessageHandler = require('./handlers/directMessageHandler'); // ADD THIS
const callHandler = require('./handlers/callHandler'); // ADD THIS
// ... other handlers

module.exports = (io) => {
  io.on('connection', (socket) => {
    console.log(`✅ [SOCKET] User connected: ${socket.id}`);
    
    // Register all handlers
    liveHandler(io, socket);
    chatHandler(io, socket);
    directMessageHandler(io, socket); // ADD THIS
    callHandler(io, socket); // ADD THIS
    // ... other handlers
    
    socket.on('disconnect', () => {
      console.log(`🔌 [SOCKET] User disconnected: ${socket.id}`);
    });
  });
};
```

---

## 4️⃣ Install Agora Token Package

```bash
npm install agora-access-token
```

---

## 5️⃣ Update `.env`

```env
# Agora Configuration
AGORA_APP_ID=your_agora_app_id
AGORA_APP_CERTIFICATE=your_agora_app_certificate

# Admin Secret Key (for authentication)
ADMIN_SECRET_KEY=your_admin_secret_key
```

---

## 6️⃣ Create Database Models

### **DirectConversation Model**

```javascript
// backend/src/models/DirectConversation.js

const mongoose = require('mongoose');

const directConversationSchema = new mongoose.Schema({
  participants: [{
    id: { type: mongoose.Schema.Types.ObjectId, required: true, refPath: 'participants.type' },
    type: { type: String, required: true, enum: ['User', 'Astrologer', 'Admin'] }
  }],
  lastMessage: String,
  lastMessageAt: Date,
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('DirectConversation', directConversationSchema);
```

### **DirectMessage Model**

```javascript
// backend/src/models/DirectMessage.js

const mongoose = require('mongoose');

const directMessageSchema = new mongoose.Schema({
  conversationId: { type: String, required: true, index: true },
  senderId: { type: String, required: true },
  senderType: { type: String, required: true, enum: ['user', 'astrologer', 'admin'] },
  recipientId: { type: String, required: true },
  recipientType: { type: String, required: true, enum: ['user', 'astrologer', 'admin'] },
  content: { type: String, required: true },
  messageType: { type: String, default: 'text', enum: ['text', 'image', 'audio', 'file'] },
  mediaUrl: String,
  timestamp: { type: Date, default: Date.now, index: true },
  status: { type: String, default: 'sent', enum: ['sent', 'delivered', 'read', 'failed'] },
  readAt: Date,
  replyToId: mongoose.Schema.Types.ObjectId
});

module.exports = mongoose.model('DirectMessage', directMessageSchema);
```

### **Call Model**

```javascript
// backend/src/models/Call.js

const mongoose = require('mongoose');

const callSchema = new mongoose.Schema({
  callerId: { type: String, required: true },
  callerType: { type: String, required: true, enum: ['user', 'astrologer', 'admin'] },
  recipientId: { type: String, required: true },
  recipientType: { type: String, required: true, enum: ['user', 'astrologer', 'admin'] },
  callType: { type: String, required: true, enum: ['voice', 'video'] },
  channelName: { type: String, required: true },
  agoraToken: String,
  status: { type: String, default: 'initiated', enum: ['initiated', 'ringing', 'accepted', 'rejected', 'connected', 'ended', 'missed'] },
  startedAt: { type: Date, default: Date.now },
  acceptedAt: Date,
  connectedAt: Date,
  endedAt: Date,
  duration: Number, // in seconds
  endReason: String
});

module.exports = mongoose.model('Call', callSchema);
```

---

## ✅ Summary

### **Files to Create:**
1. ✅ `backend/src/socket/handlers/directMessageHandler.js`
2. ✅ `backend/src/socket/handlers/callHandler.js`
3. ✅ `backend/src/models/DirectConversation.js`
4. ✅ `backend/src/models/DirectMessage.js`
5. ✅ `backend/src/models/Call.js`

### **Files to Update:**
1. ✅ `backend/src/socket/index.js` (register handlers)
2. ✅ `backend/src/socket/events.js` (already updated)
3. ✅ `backend/.env` (add Agora credentials)

### **Package to Install:**
```bash
npm install agora-access-token
```

**That's it! No REST API needed - everything works via Socket.IO!** 🚀

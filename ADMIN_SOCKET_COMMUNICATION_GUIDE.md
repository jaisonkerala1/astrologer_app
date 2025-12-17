# 📱 Admin-to-Astrologer Communication Guide

## 🎯 Overview

This guide explains how your admin dashboard can communicate with astrologers in real-time using **Socket.IO ONLY** (no REST API).

---

## 🔌 Socket.IO Events Reference

### **Direct Message Events**

| Event | Direction | Description |
|-------|-----------|-------------|
| `dm:join_conversation` | Client → Server | Join a conversation room |
| `dm:leave_conversation` | Client → Server | Leave a conversation room |
| `dm:send_message` | Client → Server | Send a message |
| `dm:message_received` | Server → Client | Receive a message (broadcast) |
| `dm:typing_start` | Client → Server | User is typing |
| `dm:typing_stop` | Client → Server | User stopped typing |
| `dm:mark_read` | Client → Server | Mark messages as read |
| `dm:history` | Client ↔ Server | Request/receive message history |

### **Call Events**

| Event | Direction | Description |
|-------|-----------|-------------|
| `call:initiate` | Client → Server | Initiate a call |
| `call:incoming` | Server → Client | Incoming call notification |
| `call:accept` | Client → Server | Accept call |
| `call:reject` | Client → Server | Reject call |
| `call:connected` | Client ↔ Server | Call connected |
| `call:end` | Client ↔ Server | End call |
| `call:token` | Server → Client | Agora token response |

---

## 💬 How to Send Messages (Admin → Astrologer)

### **Step 1: Connect to Socket.IO**

```javascript
// Admin Dashboard (Web) Example
const socket = io('https://your-backend.com', {
  auth: {
    token: 'YOUR_ADMIN_TOKEN',  // Use x-admin-key from env
  },
  transports: ['websocket', 'polling']
});

socket.on('connected', (data) => {
  console.log('✅ Connected to server:', data);
});
```

### **Step 2: Join Admin Conversation Room**

```javascript
// Join the admin conversation room
socket.emit('dm:join_conversation', {
  conversationId: 'admin_<astrologerId>',  // Format: admin_{astrologerId}
  userId: 'admin',                         // Always 'admin' for admin users
  userType: 'admin'                        // Always 'admin'
});

console.log('📥 Joined admin conversation room');
```

### **Step 3: Listen for Incoming Messages**

```javascript
// Listen for messages from astrologer
socket.on('dm:message_received', (data) => {
  console.log('📩 New message:', data);
  
  // data structure:
  // {
  //   id: 'message_id',
  //   conversationId: 'admin_<astrologerId>',
  //   senderId: '<astrologerId>',
  //   senderType: 'astrologer',
  //   content: 'Hello admin!',
  //   messageType: 'text',
  //   timestamp: '2024-01-15T10:30:00.000Z',
  //   status: 'sent'
  // }
  
  // Display message in UI
  displayMessage(data);
});
```

### **Step 4: Send Message to Astrologer**

```javascript
function sendMessageToAstrologer(astrologerId, message) {
  socket.emit('dm:send_message', {
    conversationId: `admin_${astrologerId}`,
    recipientId: astrologerId,
    recipientType: 'astrologer',
    content: message,
    messageType: 'text'
  });
  
  console.log('✅ Message sent to astrologer:', astrologerId);
}

// Usage:
sendMessageToAstrologer('675e0f0a72e5f2edd1ffa48d', 'Hi! How can I help you today?');
```

### **Step 5: Load Message History**

```javascript
// Request message history
socket.emit('dm:history', {
  conversationId: 'admin_<astrologerId>',
  page: 1,
  limit: 50
});

// Listen for history response
socket.on('dm:history', (data) => {
  console.log('📜 Message history:', data);
  
  // data structure:
  // {
  //   conversationId: 'admin_<astrologerId>',
  //   messages: [...array of messages...],
  //   total: 150,
  //   page: 1,
  //   limit: 50
  // }
  
  displayMessageHistory(data.messages);
});
```

---

## 📞 How to Make Calls (Admin → Astrologer)

### **Step 1: Initiate a Video Call**

```javascript
function initiateVideoCall(astrologerId) {
  const channelName = `admin_call_${Date.now()}`;
  
  socket.emit('call:initiate', {
    recipientId: astrologerId,
    recipientType: 'astrologer',
    callType: 'video',  // or 'voice'
    channelName: channelName
  });
  
  console.log('📞 Initiating video call to:', astrologerId);
  
  // Listen for Agora token
  socket.once('call:token', (data) => {
    console.log('🔑 Received Agora token:', data);
    
    // data structure:
    // {
    //   callId: '<call_id>',
    //   agoraToken: '<token>',
    //   channelName: 'admin_call_1234567890',
    //   uid: 0
    // }
    
    // Initialize Agora with the token
    startAgoraCall(data.agoraToken, data.channelName, data.callId);
  });
}
```

### **Step 2: Handle Incoming Calls from Astrologer**

```javascript
// Listen for incoming calls
socket.on('call:incoming', (data) => {
  console.log('📞 Incoming call:', data);
  
  // data structure:
  // {
  //   callId: '<call_id>',
  //   callerId: '<astrologerId>',
  //   callerName: 'Astrologer Name',
  //   callerType: 'astrologer',
  //   callType: 'video',
  //   agoraToken: '<token>',
  //   channelName: 'video_123456',
  //   callerAvatar: 'https://...'
  // }
  
  // Show incoming call UI
  showIncomingCallUI(data);
});

// Accept the call
function acceptCall(callId, callerId) {
  socket.emit('call:accept', {
    callId: callId,
    contactId: callerId
  });
  
  console.log('✅ Call accepted:', callId);
  
  // Navigate to call screen
  openCallScreen(callId);
}

// Reject the call
function rejectCall(callId, callerId) {
  socket.emit('call:reject', {
    callId: callId,
    contactId: callerId,
    reason: 'declined'
  });
  
  console.log('❌ Call rejected:', callId);
}
```

### **Step 3: During Call - Notify Connection**

```javascript
// Notify when call is connected
function notifyCallConnected(callId, contactId) {
  socket.emit('call:connected', {
    callId: callId,
    contactId: contactId
  });
  
  console.log('🔗 Call connected notification sent');
}
```

### **Step 4: End Call**

```javascript
// End the call
function endCall(callId, contactId, duration) {
  socket.emit('call:end', {
    callId: callId,
    contactId: contactId,
    duration: duration  // in seconds
  });
  
  console.log('📴 Call ended, duration:', duration, 'seconds');
  
  // Clean up Agora
  leaveAgoraChannel();
}
```

---

## 🧪 Testing Guide for Admin Team

### **Test 1: Send Message to Astrologer**

```javascript
// 1. Connect to Socket.IO
const socket = io('http://localhost:8000', {
  auth: { token: 'your-admin-token' }
});

// 2. Wait for connection
socket.on('connected', () => {
  console.log('✅ Connected');
  
  // 3. Join conversation
  socket.emit('dm:join_conversation', {
    conversationId: 'admin_675e0f0a72e5f2edd1ffa48d',
    userId: 'admin',
    userType: 'admin'
  });
  
  // 4. Send message
  setTimeout(() => {
    socket.emit('dm:send_message', {
      conversationId: 'admin_675e0f0a72e5f2edd1ffa48d',
      recipientId: '675e0f0a72e5f2edd1ffa48d',
      recipientType: 'astrologer',
      content: 'Hello from admin!',
      messageType: 'text'
    });
    console.log('📤 Message sent');
  }, 1000);
});

// 5. Listen for response
socket.on('dm:message_received', (data) => {
  console.log('📩 Received:', data.content);
});
```

### **Test 2: Initiate Video Call**

```javascript
// 1. Initiate call
socket.emit('call:initiate', {
  recipientId: '675e0f0a72e5f2edd1ffa48d',
  recipientType: 'astrologer',
  callType: 'video',
  channelName: `admin_test_${Date.now()}`
});

// 2. Wait for token
socket.on('call:token', (data) => {
  console.log('🔑 Token received:', data.agoraToken);
  // Use token to join Agora channel
});

// 3. Listen for call status
socket.on('call:accept', (data) => {
  console.log('✅ Astrologer accepted call');
});

socket.on('call:reject', (data) => {
  console.log('❌ Astrologer rejected call');
});
```

---

## 📊 Complete Admin Dashboard Example

```html
<!DOCTYPE html>
<html>
<head>
  <title>Admin Dashboard - Chat</title>
  <script src="https://cdn.socket.io/4.5.4/socket.io.min.js"></script>
</head>
<body>
  <div id="messages"></div>
  <input id="messageInput" type="text" placeholder="Type message...">
  <button onclick="sendMessage()">Send</button>
  <button onclick="initiateCall()">Video Call</button>

  <script>
    const ASTROLOGER_ID = '675e0f0a72e5f2edd1ffa48d';
    const CONVERSATION_ID = `admin_${ASTROLOGER_ID}`;
    
    // Connect
    const socket = io('http://localhost:8000', {
      auth: { token: 'your-admin-key' }
    });
    
    socket.on('connected', () => {
      console.log('✅ Connected');
      
      // Join conversation
      socket.emit('dm:join_conversation', {
        conversationId: CONVERSATION_ID,
        userId: 'admin',
        userType: 'admin'
      });
      
      // Load history
      socket.emit('dm:history', {
        conversationId: CONVERSATION_ID,
        page: 1,
        limit: 50
      });
    });
    
    // Receive messages
    socket.on('dm:message_received', (data) => {
      if (data.conversationId === CONVERSATION_ID) {
        displayMessage(data);
      }
    });
    
    // Receive history
    socket.on('dm:history', (data) => {
      if (data.conversationId === CONVERSATION_ID) {
        data.messages.forEach(msg => displayMessage(msg));
      }
    });
    
    // Send message
    function sendMessage() {
      const input = document.getElementById('messageInput');
      const message = input.value.trim();
      
      if (message) {
        socket.emit('dm:send_message', {
          conversationId: CONVERSATION_ID,
          recipientId: ASTROLOGER_ID,
          recipientType: 'astrologer',
          content: message,
          messageType: 'text'
        });
        
        input.value = '';
        displayMessage({
          content: message,
          senderType: 'admin',
          timestamp: new Date().toISOString(),
          status: 'sent'
        });
      }
    }
    
    // Display message
    function displayMessage(msg) {
      const div = document.getElementById('messages');
      const p = document.createElement('p');
      p.textContent = `[${msg.senderType}] ${msg.content}`;
      div.appendChild(p);
    }
    
    // Initiate call
    function initiateCall() {
      socket.emit('call:initiate', {
        recipientId: ASTROLOGER_ID,
        recipientType: 'astrologer',
        callType: 'video',
        channelName: `admin_call_${Date.now()}`
      });
      
      socket.once('call:token', (data) => {
        alert(`Agora Token: ${data.agoraToken}\nChannel: ${data.channelName}`);
        // Initialize Agora SDK here
      });
    }
  </script>
</body>
</html>
```

---

## ✅ Summary

### **For Messaging:**
1. Connect with Socket.IO using admin token
2. Join conversation: `admin_<astrologerId>`
3. Listen for `dm:message_received`
4. Send with `dm:send_message`
5. Load history with `dm:history`

### **For Calls:**
1. Initiate with `call:initiate`
2. Receive token via `call:token`
3. Accept/reject with `call:accept` / `call:reject`
4. Notify with `call:connected`
5. End with `call:end`

### **No REST API needed - everything is Socket.IO!** 🚀

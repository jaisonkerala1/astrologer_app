# Backend FCM Integration Guide

## 📦 Required Packages

```bash
cd backend
npm install firebase-admin
```

---

## 🔧 Backend Implementation

### 1. Initialize Firebase Admin SDK

**`backend/src/config/firebase.js`**
```javascript
const admin = require('firebase-admin');

// Initialize Firebase Admin (use service account JSON from Firebase Console)
const serviceAccount = require('../../firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const messaging = admin.messaging();

module.exports = { messaging };
```

---

### 2. FCM Token Storage

**Add to Astrologer Model (`backend/src/models/Astrologer.js`)**
```javascript
const astrologerSchema = new mongoose.Schema({
  // ... existing fields ...
  
  fcmTokens: [{
    token: String,
    platform: { type: String, enum: ['android', 'ios', 'web'] },
    lastUpdated: { type: Date, default: Date.now },
  }],
}, { timestamps: true });
```

**Add to Customer Model (for future customer app)**
```javascript
const customerSchema = new mongoose.Schema({
  // ... existing fields ...
  
  fcmTokens: [{
    token: String,
    platform: { type: String, enum: ['android', 'ios', 'web'] },
    lastUpdated: { type: Date, default: Date.now },
  }],
}, { timestamps: true });
```

---

### 3. FCM Token Registration Endpoint

**`backend/src/routes/fcm.js`**
```javascript
const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const Astrologer = require('../models/Astrologer');
const Customer = require('../models/Customer');

/**
 * POST /api/fcm/register
 * Register FCM token for push notifications
 */
router.post('/register', authMiddleware, async (req, res) => {
  try {
    const { fcmToken, platform } = req.body;
    const { userType, userId } = req.user; // From auth middleware
    
    if (!fcmToken) {
      return res.status(400).json({
        success: false,
        message: 'FCM token is required',
      });
    }
    
    // Select model based on user type
    const Model = userType === 'astrologer' ? Astrologer : Customer;
    
    // Find user and update FCM tokens
    const user = await Model.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }
    
    // Remove old token if exists (same device)
    user.fcmTokens = user.fcmTokens.filter(t => t.token !== fcmToken);
    
    // Add new token
    user.fcmTokens.push({
      token: fcmToken,
      platform: platform || 'android',
      lastUpdated: new Date(),
    });
    
    // Keep only last 3 tokens per user (multiple devices)
    if (user.fcmTokens.length > 3) {
      user.fcmTokens = user.fcmTokens.slice(-3);
    }
    
    await user.save();
    
    console.log(`✅ [FCM] Token registered for ${userType}: ${userId}`);
    
    res.json({
      success: true,
      message: 'FCM token registered successfully',
    });
  } catch (error) {
    console.error('❌ [FCM] Token registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to register FCM token',
    });
  }
});

/**
 * POST /api/fcm/unregister
 * Remove FCM token (on logout)
 */
router.post('/unregister', authMiddleware, async (req, res) => {
  try {
    const { fcmToken } = req.body;
    const { userType, userId } = req.user;
    
    const Model = userType === 'astrologer' ? Astrologer : Customer;
    
    await Model.findByIdAndUpdate(userId, {
      $pull: { fcmTokens: { token: fcmToken } },
    });
    
    res.json({
      success: true,
      message: 'FCM token removed successfully',
    });
  } catch (error) {
    console.error('❌ [FCM] Token removal error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to remove FCM token',
    });
  }
});

module.exports = router;
```

**Register route in `backend/src/server.js`**
```javascript
const fcmRoutes = require('./routes/fcm');
app.use('/api/fcm', fcmRoutes);
```

---

### 4. FCM Notification Service

**`backend/src/services/fcmService.js`**
```javascript
const { messaging } = require('../config/firebase');

class FcmService {
  /**
   * Send FCM notification to user
   * @param {String} userId - User ID
   * @param {String} userType - 'astrologer' or 'customer'
   * @param {Object} notification - Notification data
   */
  static async sendNotification(userId, userType, notification) {
    try {
      // Get user's FCM tokens
      const Model = userType === 'astrologer' 
        ? require('../models/Astrologer')
        : require('../models/Customer');
      
      const user = await Model.findById(userId).select('fcmTokens');
      if (!user || !user.fcmTokens || user.fcmTokens.length === 0) {
        console.log(`⚠️ [FCM] No tokens found for ${userType}: ${userId}`);
        return { success: false, reason: 'no_tokens' };
      }
      
      const tokens = user.fcmTokens.map(t => t.token);
      
      // Construct FCM message
      const message = {
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: notification.data || {},
        tokens: tokens,
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: notification.channelId || 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };
      
      // Send to multiple devices
      const response = await messaging.sendEachForMulticast(message);
      
      console.log(`✅ [FCM] Sent to ${userType} ${userId}: ${response.successCount} success, ${response.failureCount} failed`);
      
      // Remove invalid tokens
      if (response.failureCount > 0) {
        const invalidTokens = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            invalidTokens.push(tokens[idx]);
          }
        });
        
        if (invalidTokens.length > 0) {
          await Model.findByIdAndUpdate(userId, {
            $pull: { fcmTokens: { token: { $in: invalidTokens } } },
          });
          console.log(`🗑️ [FCM] Removed ${invalidTokens.length} invalid tokens`);
        }
      }
      
      return {
        success: true,
        successCount: response.successCount,
        failureCount: response.failureCount,
      };
    } catch (error) {
      console.error('❌ [FCM] Send notification error:', error);
      return { success: false, error: error.message };
    }
  }
  
  /**
   * Send incoming call notification
   */
  static async sendCallNotification(recipientId, recipientType, callData) {
    return this.sendNotification(recipientId, recipientType, {
      title: `Incoming ${callData.callType === 'video' ? 'Video' : 'Voice'} Call`,
      body: `${callData.callerName} is calling...`,
      channelId: 'calls',
      data: {
        type: callData.callType === 'video' ? 'video_call' : 'call',
        callId: callData.callId,
        callerId: callData.callerId,
        callerName: callData.callerName,
        callerType: callData.callerType,
        callType: callData.callType,
        channelName: callData.channelName,
        agoraToken: callData.token,
        agoraAppId: process.env.AGORA_APP_ID,
      },
    });
  }
  
  /**
   * Send new message notification
   */
  static async sendMessageNotification(recipientId, recipientType, messageData) {
    return this.sendNotification(recipientId, recipientType, {
      title: messageData.senderName,
      body: messageData.content,
      channelId: 'messages',
      data: {
        type: 'message',
        conversationId: messageData.conversationId,
        senderId: messageData.senderId,
        senderName: messageData.senderName,
        content: messageData.content,
      },
    });
  }
}

module.exports = FcmService;
```

---

### 5. Integrate with Call Handler

**Update `backend/src/socket/handlers/callHandler.js`**
```javascript
const FcmService = require('../../services/fcmService');

async function handleCallInitiate(io, socket, data) {
  try {
    // ... existing call logic ...
    
    // Emit socket event (for foreground)
    io.to(`${EVENTS.ROOM_PREFIX.ASTROLOGER}:${recipientId}`).emit(
      EVENTS.CALL.INCOMING,
      callData
    );
    
    // Send FCM notification (for background/locked)
    await FcmService.sendCallNotification(
      recipientId,
      data.recipientType,
      callData
    );
    
    console.log(`✅ [CALL] Notification sent to ${recipientId}`);
  } catch (error) {
    console.error('❌ [CALL] Error:', error);
  }
}
```

**Update `backend/src/socket/handlers/directMessageHandler.js`**
```javascript
const FcmService = require('../../services/fcmService');

async function handleDirectMessage(io, socket, data) {
  try {
    // ... existing message logic ...
    
    // Emit socket event (for foreground)
    io.to(recipientRoom).emit(EVENTS.DM.MESSAGE_RECEIVED, messageData);
    
    // Send FCM notification (for background)
    await FcmService.sendMessageNotification(
      recipientId,
      data.recipientType,
      messageData
    );
  } catch (error) {
    console.error('❌ [DM] Error:', error);
  }
}
```

---

## 🔑 Environment Variables

**Add to `backend/.env`**
```env
# Agora (already exists)
AGORA_APP_ID=your_app_id
AGORA_APP_CERTIFICATE=your_certificate

# Firebase (new)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
```

---

## 📱 Flutter Integration

**Update `FcmService.registerTokenWithBackend`**
```dart
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

Future<bool> registerTokenWithBackend({
  required String apiUrl,
  required String authToken,
  required String userId,
  required String userType,
}) async {
  if (_fcmToken == null) return false;

  try {
    final dio = Dio();
    final response = await dio.post(
      '${ApiConstants.baseUrl}/fcm/register',
      data: {
        'fcmToken': _fcmToken,
        'platform': Platform.isAndroid ? 'android' : 'ios',
      },
      options: Options(
        headers: {'Authorization': 'Bearer $authToken'},
      ),
    );

    return response.data['success'] == true;
  } catch (e) {
    print('❌ [FCM] Registration failed: $e');
    return false;
  }
}
```

---

## ✅ Testing

### Test FCM Token Registration
```bash
curl -X POST http://localhost:5000/api/fcm/register \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "fcmToken": "test_token_123",
    "platform": "android"
  }'
```

### Test Call Notification
```javascript
// In your admin dashboard or test script
const FcmService = require('./src/services/fcmService');

await FcmService.sendCallNotification(
  'astrologer_id_here',
  'astrologer',
  {
    callId: 'test_call_123',
    callerId: 'admin',
    callerName: 'Admin',
    callerType: 'admin',
    callType: 'voice',
    channelName: 'test_channel',
    token: 'test_agora_token',
  }
);
```

---

## 🎯 Complete Flow

```
1. App Launch:
   ├─→ FcmService.initialize()
   ├─→ Get FCM token
   └─→ Save to local storage

2. User Logs In:
   ├─→ FcmBloc.add(RegisterFcmTokenEvent)
   ├─→ POST /api/fcm/register
   └─→ Token saved in database

3. Admin Initiates Call:
   ├─→ Socket.IO emit (foreground detection)
   └─→ FCM notification (background/locked)

4. Device Receives Notification:
   ├─→ OS wakes device (even if locked)
   ├─→ FcmService receives message
   ├─→ FcmBloc emits FcmIncomingCallNotification
   ├─→ App.dart BlocListener catches it
   ├─→ Triggers CallBloc.add(IncomingCallEvent)
   └─→ Shows IncomingCallScreen

5. User Accepts Call:
   ├─→ Joins Agora channel
   └─→ Call proceeds normally
```

---

## 📝 Summary

✅ **Backend**: FCM Admin SDK + token storage + notification service  
✅ **Flutter**: FcmService → FcmBloc → CallBloc → UI  
✅ **Works**: Foreground, Background, Phone Locked, App Killed  
✅ **Reusable**: Astrologer app + Customer app (same code)  

**This is the same architecture WhatsApp, Telegram, and all professional apps use!** 🚀







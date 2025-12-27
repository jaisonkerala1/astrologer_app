# Socket.IO Communication Tests

## 🎯 Purpose
Test the admin-to-astrologer real-time communication features:
- Direct messaging
- Typing indicators
- Message history
- Voice/video call initiation

## 📋 Prerequisites

1. **Backend deployed on Railway** ✅
2. **Get a real astrologer ID** from your database:
   ```bash
   # In MongoDB or Railway logs, find an astrologer ID
   # Example: 675e0f0a72e5f2edd1ffa48d
   ```

3. **Update test scripts** with the astrologer ID:
   - Open `test-socket-auto.js` or `test-socket-communication.js`
   - Change line 6: `const TEST_ASTROLOGER_ID = 'YOUR_ACTUAL_ASTROLOGER_ID';`

## 🚀 Run Tests

### Option 1: Automated Test (Quick)
```bash
cd C:\Users\jaiso\Desktop\astrologer_app\backend
node test-socket-auto.js
```

**What it tests:**
- ✅ Socket.IO connection
- ✅ Join conversation
- ✅ Send message
- ✅ Load message history
- ✅ Typing indicators
- ✅ Call initiation

**Output:**
```
🧪 AUTOMATED SOCKET.IO TESTS
✅ Connection test: PASSED
✅ Join conversation: PASSED
✅ Message sent: "Test message..."
✅ History loaded: 5 messages
✅ Typing indicator: WORKING
✅ Call initiated: video

📊 TEST RESULTS
✅ 6/6 tests passed (100%)
```

### Option 2: Interactive Test (Manual)
```bash
node test-socket-communication.js
```

**Interactive commands:**
- `1` - Send test message
- `2` - Load message history
- `3` - Start typing indicator
- `4` - Stop typing indicator
- `5` - Initiate voice call
- `6` - Initiate video call
- `m` - Send custom message
- `h` - Show help
- `q` - Quit

## 🔍 What to Check

### 1. Backend Logs (Railway)
After running tests, check Railway logs for:
```
✅ [SOCKET] User connected: admin (socket_id)
📩 [DM] Message sent from admin to astrologer
📞 [CALL] Call initiated: admin -> astrologer
```

### 2. Astrologer Flutter App
If an astrologer is online in the Flutter app, they should receive:
- Real-time messages from admin
- Typing indicators when admin types
- Incoming call notifications

### 3. MongoDB Database
Check these collections after tests:
- `directconversations` - Should have admin_astrologer conversation
- `directmessages` - Should have test messages
- `calls` - Should have call records

## ⚠️ Troubleshooting

### Test fails with "Connection timeout"
- **Check**: Railway backend is running
- **Check**: `BACKEND_URL` in test script is correct
- **Check**: Socket.IO handlers are registered in `backend/src/socket/index.js`

### Test connects but no messages
- **Check**: Astrologer ID exists in database
- **Check**: `directMessageHandler.js` is loaded
- **Check**: Railway env vars: `ADMIN_SECRET_KEY=admin123`

### Call test fails
- **Check**: Railway env vars set:
  - `AGORA_APP_ID`
  - `AGORA_APP_CERTIFICATE`
- **Check**: `callHandler.js` is loaded
- **Check**: `agora-access-token` npm package installed

## 📝 Expected Test Results

### ✅ All tests should pass if:
1. Backend deployed on Railway
2. Socket.IO handlers registered
3. MongoDB connection working
4. Agora credentials set in Railway env vars

### ❌ Common failures:
- **Connection failed**: Backend not running or wrong URL
- **Message not sent**: `directMessageHandler` not loaded
- **No history**: No previous messages in database (OK for first test)
- **Call failed**: Agora credentials missing

## 🎯 Next Steps After Tests Pass

1. **Admin Dashboard**: Once Vercel deploys, test from browser
2. **Flutter App**: Test receiving messages/calls on astrologer device
3. **Production**: Test with real astrologers

## 📞 Test Flow Diagram

```
Admin Test Script
      ↓
   Socket.IO
      ↓
Railway Backend
      ↓
  MongoDB (save)
      ↓
Astrologer Flutter App (real-time notification)
```

## 🔧 Customization

To test different features, edit the test scripts:

```javascript
// Test with different message types
messageType: 'image',  // 'text', 'image', 'audio', 'file'

// Test with different call types
callType: 'voice',  // 'voice', 'video'

// Load more history
limit: 50,  // Default: 20
```

---

**Need help?** Check Railway logs for detailed error messages.






























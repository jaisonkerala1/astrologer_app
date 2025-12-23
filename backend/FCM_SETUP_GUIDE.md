# 🔔 FCM Push Notifications Setup Guide

## ✅ Backend Implementation Complete!

The backend FCM infrastructure has been fully implemented. This guide will help you configure Firebase credentials.

---

## 📋 What's Been Implemented

### 1. **Database Models Updated**
- ✅ `Astrologer.js` - Added `fcmTokens` array field
- ✅ `User.js` - Added `fcmTokens` array field (replaces old `fcmToken`)

### 2. **Firebase Configuration**
- ✅ `src/config/firebase.js` - Firebase Admin SDK initialization
- ✅ Supports both local (JSON file) and production (env vars) configuration

### 3. **FCM Service**
- ✅ `src/services/fcmService.js` - Core notification service
- ✅ `sendCallNotification()` - For incoming calls
- ✅ `sendMessageNotification()` - For new messages
- ✅ Automatic invalid token cleanup

### 4. **API Routes**
- ✅ `POST /api/fcm/register` - Register FCM token
- ✅ `POST /api/fcm/unregister` - Remove FCM token on logout
- ✅ `GET /api/fcm/tokens` - Debug endpoint to check registered tokens

### 5. **Socket.IO Integration**
- ✅ `callHandler.js` - Sends FCM on incoming calls
- ✅ `directMessageHandler.js` - Sends FCM on new messages

### 6. **Dependencies**
- ✅ `firebase-admin` package added to `package.json`

---

## 🔑 Step 1: Get Firebase Credentials

### Option A: Download Service Account JSON (Recommended for Production)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **astrologer-app-9428a**
3. Click the ⚙️ gear icon → **Project Settings**
4. Go to **Service Accounts** tab
5. Click **Generate New Private Key**
6. Save the downloaded JSON file

### Option B: Use Environment Variables (For Railway)

From the downloaded JSON, extract these values:

```json
{
  "project_id": "astrologer-app-9428a",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@astrologer-app-9428a.iam.gserviceaccount.com"
}
```

---

## 🚂 Step 2: Configure Railway Environment Variables

Add these to your Railway backend environment:

```env
FIREBASE_PROJECT_ID=astrologer-app-9428a
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_ACTUAL_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@astrologer-app-9428a.iam.gserviceaccount.com
```

⚠️ **Important Notes:**
- Keep the quotes around `FIREBASE_PRIVATE_KEY`
- Include the `\n` characters as-is (they represent newlines)
- The private key should be one long string with `\n` separators

---

## 💻 Step 3: Local Development (Optional)

If testing locally, you can use the JSON file:

1. Place the downloaded service account JSON at:
   ```
   backend/firebase-service-account.json
   ```

2. Update the placeholder values in the existing file

3. **DO NOT commit this file to Git!** (Already in `.gitignore`)

---

## 🧪 Step 4: Test the Implementation

### Test 1: Check Server Startup

After deployment, check Railway logs for:

```
✅ [FCM] Firebase Admin initialized with environment variables
✅ FCM routes loaded
```

### Test 2: Register Token from Flutter App

The Flutter app should automatically call:

```dart
POST https://your-backend.railway.app/api/fcm/register
Headers: { Authorization: Bearer YOUR_JWT_TOKEN }
Body: {
  "fcmToken": "d8jzOOu_RZeepM-fKIzp...",
  "platform": "android"
}
```

Response:
```json
{
  "success": true,
  "message": "FCM token registered successfully"
}
```

### Test 3: Send a Test Message

From admin dashboard, send a message to an astrologer. Check backend logs:

```
✅ [FCM] Sent to astrologer John Doe: 1 success, 0 failed
```

### Test 4: Initiate a Test Call

From admin dashboard, call an astrologer. They should receive:
- Socket.IO event (if app is in foreground)
- FCM notification (if app is in background/locked)

---

## 🔍 Troubleshooting

### Issue: "FCM credentials not found"

**Solution:** Check Railway environment variables are set correctly.

```bash
# In Railway, verify these are set:
echo $FIREBASE_PROJECT_ID
echo $FIREBASE_CLIENT_EMAIL
# (Don't echo FIREBASE_PRIVATE_KEY in logs!)
```

### Issue: "Failed to send notification"

**Possible causes:**
1. User has no FCM tokens registered (they haven't logged in on Flutter app)
2. Invalid Firebase credentials
3. Firebase project doesn't match the app's `google-services.json`

**Solution:** Check backend logs for specific error messages.

### Issue: Notifications not received on device

**Checklist:**
1. ✅ Flutter app has called `/api/fcm/register`
2. ✅ Token is saved in database (check with `/api/fcm/tokens`)
3. ✅ Firebase credentials are correct
4. ✅ App's `google-services.json` matches Firebase project
5. ✅ Android FCM channels are configured correctly

---

## 📊 Architecture Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     Call/Message Event                       │
└─────────────────────┬───────────────────────────────────────┘
                      │
         ┌────────────┴────────────┐
         │                         │
    Socket.IO                   FCM Push
  (Foreground)              (Background/Locked)
         │                         │
         ▼                         ▼
   ┌─────────┐            ┌──────────────┐
   │ Flutter │            │   Firebase   │
   │   App   │◄───────────┤   Messaging  │
   │(Active) │            │   Service    │
   └─────────┘            └──────────────┘
                                 │
                                 ▼
                          Device wakes up
                          Shows notification
                          Opens app on tap
```

---

## 🎯 Key Features

✅ **Multi-device support** - Each user can have up to 3 FCM tokens (multiple devices)  
✅ **Automatic cleanup** - Invalid tokens are removed automatically  
✅ **Graceful degradation** - If FCM is not configured, Socket.IO still works  
✅ **Platform agnostic** - Works for Android, iOS, and Web  
✅ **Type-specific notifications** - Different channels for calls vs messages  

---

## 🔐 Security Notes

1. **Never commit `firebase-service-account.json` to Git**
2. **Use environment variables in production (Railway)**
3. **Rotate credentials if exposed**
4. **Verify JWT tokens before registering FCM tokens** (already implemented)

---

## 📝 Next Steps

1. ✅ Get Firebase service account credentials
2. ✅ Add environment variables to Railway
3. ✅ Deploy backend (automatic via Git push)
4. ✅ Test with Flutter app
5. ✅ Monitor backend logs for FCM activity

---

## 🚀 Deployment Commands

```bash
# Push to GitHub (auto-deploys to Railway)
git add .
git commit -m "Add FCM push notifications backend"
git push origin main

# Check Railway logs
# Visit Railway dashboard → Your Backend → Logs

# Look for:
# ✅ [FCM] Firebase Admin initialized
# ✅ FCM routes loaded
```

---

## 📞 Support

If you encounter issues:

1. Check Railway logs for error messages
2. Verify Firebase credentials in Railway environment
3. Test with Postman/curl to isolate issues
4. Check Flutter app logs for token registration

---

**🎉 Implementation Complete! Push to Git when ready to deploy.**

















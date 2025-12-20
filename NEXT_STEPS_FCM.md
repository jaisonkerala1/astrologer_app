# 🚀 Next Steps to Enable Background Calls (WhatsApp-style)

## ✅ What's Done (Just Now)

- ✅ Firebase packages added to pubspec.yaml
- ✅ FcmService & FcmBloc created (proper BLoC architecture)
- ✅ Registered in service_locator.dart
- ✅ Firebase initialized in main.dart
- ✅ FcmBloc integrated in app.dart

**Current Status:**
- ✅ Foreground calls work (Socket.IO)
- ❌ Background/locked calls DON'T work yet (need Firebase setup + backend)

---

## 📋 Remaining Steps

### **Step 1: Install Packages** (2 minutes)
```bash
cd c:\Users\jaiso\Desktop\astrologer_app
flutter pub get
flutter clean
flutter pub get
```

---

### **Step 2: Setup Firebase Project** (10 minutes)

1. **Go to Firebase Console:**
   - https://console.firebase.google.com/
   - Click "Add project"
   - Name: "Astrologer App"
   - Disable Analytics (optional)

2. **Add Android App:**
   - Click Android icon
   - **Package name:** Open `android/app/build.gradle` and find `applicationId`
     (Probably: `com.example.astrologer_app`)
   - App nickname: Astrologer App
   - Click "Register app"

3. **Download google-services.json:**
   - Download the file
   - **Place it in:** `android/app/google-services.json`

4. **Update Android Configuration:**

   **`android/build.gradle`** (project-level):
   ```gradle
   buildscript {
       repositories {
           google()
           mavenCentral()
       }
       dependencies {
           classpath 'com.android.tools.build:gradle:8.1.0'
           classpath 'org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.22'
           classpath 'com.google.gms:google-services:4.4.0'  // ← ADD THIS
       }
   }
   ```

   **`android/app/build.gradle`** (app-level, at the very bottom):
   ```gradle
   // ... existing code ...
   
   apply plugin: 'com.google.gms.google-services'  // ← ADD THIS AT THE END
   ```

5. **Test Build:**
   ```bash
   flutter build apk --debug
   ```

---

### **Step 3: Backend Setup** (30 minutes)

**See `BACKEND_FCM_INTEGRATION.md` for complete guide.**

Quick summary:

1. **Install firebase-admin:**
   ```bash
   cd C:\Users\jaiso\Desktop\admin_dashboard\backend
   npm install firebase-admin
   ```

2. **Download Service Account:**
   - Firebase Console → Project Settings → Service Accounts
   - Click "Generate new private key"
   - Save as `backend/firebase-service-account.json`

3. **Add to Astrologer Model:**
   ```javascript
   // backend/src/models/Astrologer.js
   fcmTokens: [{
     token: String,
     platform: { type: String, enum: ['android', 'ios', 'web'] },
     lastUpdated: { type: Date, default: Date.now },
   }],
   ```

4. **Create FCM Service:**
   - Copy code from `BACKEND_FCM_INTEGRATION.md` → Section 4
   - Create `backend/src/services/fcmService.js`

5. **Update Call Handler:**
   - Modify `backend/src/socket/handlers/callHandler.js`
   - Add FCM notification after Socket.IO emit:
   ```javascript
   const FcmService = require('../../services/fcmService');
   
   // After emitting socket event
   await FcmService.sendCallNotification(
     recipientId,
     data.recipientType,
     callData
   );
   ```

6. **Restart Backend:**
   ```bash
   npm run dev
   ```

---

### **Step 4: Test on Real Device** (Required!)

```bash
# Build and install
flutter build apk --debug
flutter install --device-id=YOUR_DEVICE_ID

# Test scenarios:
1. App in FOREGROUND → Admin calls → Should work via Socket.IO
2. App in BACKGROUND → Admin calls → Should show notification + incoming call screen
3. Phone LOCKED → Admin calls → Should wake device + show incoming call screen
4. App KILLED → Admin calls → Should start app + show incoming call screen
```

---

## 🎯 Complete Flow (After All Steps)

```
Admin initiates call from dashboard
    ↓
Backend receives call request
    ↓
Backend does TWO things in parallel:
    ├─→ Socket.IO emit (for foreground)
    └─→ FCM notification (for background/locked)
    ↓
Device receives notification:
    ├─ If app FOREGROUND: Socket.IO → CallBloc → Shows IncomingCallScreen
    └─ If app BACKGROUND/LOCKED: FCM → FcmBloc → CallBloc → Shows IncomingCallScreen
    ↓
User sees incoming call screen (either way!)
    ↓
User accepts → Joins Agora channel → Call starts
```

---

## ⚠️ Common Issues & Fixes

### **Issue 1: "google-services.json not found"**
- Make sure file is in `android/app/google-services.json`
- Run `flutter clean && flutter pub get`

### **Issue 2: "Duplicate class found" error**
- Update `android/gradle.properties`:
  ```properties
  android.useAndroidX=true
  android.enableJetifier=true
  ```

### **Issue 3: FCM token is null**
- Check Firebase Console → Cloud Messaging is enabled
- Check app has notification permissions
- Check logs for "FCM Token: " message

### **Issue 4: Notifications not received when app killed**
- This is EXPECTED behavior in debug mode on some devices
- Build RELEASE APK for proper testing:
  ```bash
  flutter build apk --release
  ```

---

## 🎓 Testing Checklist

- [ ] Firebase project created
- [ ] google-services.json downloaded and placed
- [ ] `flutter pub get` runs successfully
- [ ] `flutter build apk` completes without errors
- [ ] App launches on device
- [ ] Logs show "Firebase initialized"
- [ ] Logs show "FCM Token: ..."
- [ ] Backend has firebase-admin installed
- [ ] Backend has fcmService.js created
- [ ] Call handler sends FCM notifications
- [ ] Foreground call works (Socket.IO)
- [ ] Background call works (FCM)
- [ ] Locked phone call works (FCM)

---

## 📝 Summary

**What you have NOW:**
- ✅ Complete FCM BLoC architecture (production-ready code)
- ✅ Proper separation of concerns
- ✅ Reusable for customer app

**What you need to DO:**
1. Run `flutter pub get`
2. Setup Firebase project (10 min)
3. Backend FCM integration (30 min)
4. Test on real device

**Total time:** ~45 minutes

**After that:** ✅ Background calls work like WhatsApp! 🎉







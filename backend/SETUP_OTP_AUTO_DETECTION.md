# 🚀 OTP Auto-Detection Setup Guide for Backend

## Overview

Your backend now supports **cross-platform OTP auto-detection**:
- **Android**: SMS Retriever API (zero permission)
- **iOS**: Native autofill (built-in)

## ⚙️ Configuration Required

### 1. Get App Hash Signatures from Frontend Team

**You need TWO different hashes:**

#### Debug Build Hash:
```
Run this in Flutter app (debug mode):
await OTPHelper.printAppSignature();

Example output: FA+9qCX9VSu
```

#### Release Build Hash:
```
Build release APK and run:
await OTPHelper.printAppSignature();

Example output: XY+abcd1234  (different from debug!)
```

### 2. Update Environment Variables

Add to your `.env` file:

```env
# Android App Hash - Use RELEASE hash for production!
ANDROID_APP_HASH=FA+9qCX9VSu

# iOS Domain (optional but recommended)
IOS_DOMAIN=astrologerapp.com
```

**IMPORTANT:** For production on Railway, use the **RELEASE build hash**, not debug!

---

## 📨 SMS Message Format

The SMS now looks like this:

```
Your Astrologer App verification code: 123456

This code expires in 5 minutes.

@astrologerapp.com #123456
FA+9qCX9VSu
```

### Format Breakdown:
- Line 1: User-friendly message with OTP
- Line 2: Expiry information
- Line 3: Blank line
- Line 4: iOS domain + OTP (for iOS autofill)
- Line 5: Android hash signature (for Android auto-detection)

---

## 🧪 Testing

### Test the SMS Format:

1. **Send Test OTP:**
   ```bash
   curl -X POST https://your-backend.railway.app/api/auth/send-otp \
     -H "Content-Type: application/json" \
     -d '{"phone": "+1234567890"}'
   ```

2. **Check Twilio Logs:**
   - Verify message includes hash signature
   - Confirm message is under 140 characters

3. **Test on Real Devices:**
   - **Android**: Should auto-fill instantly (no permission dialog)
   - **iOS**: Should show OTP above keyboard

---

## 🔧 Railway Deployment

### Update Environment Variables on Railway:

1. Go to Railway Dashboard
2. Select your backend service
3. Go to Variables tab
4. Add:
   ```
   ANDROID_APP_HASH = FA+9qCX9VSu
   IOS_DOMAIN = astrologerapp.com
   ```
5. Redeploy

### Or use Railway CLI:

```bash
railway variables set ANDROID_APP_HASH=FA+9qCX9VSu
railway variables set IOS_DOMAIN=astrologerapp.com
```

---

## ⚠️ Important Notes

### 1. Different Hashes for Debug vs Release

| Build Type | Hash | Use When |
|------------|------|----------|
| Debug | `ABC123xyz` | Local development |
| Release | `DEF456uvw` | Production/Railway |

**Always use RELEASE hash in production!**

### 2. Message Length

- Keep total message under **140 characters**
- Current format: ~120 characters ✅
- Room for customization

### 3. Hash Format

- Exactly **11 characters**
- Contains: letters, numbers, `+`, `/`
- Example: `FA+9qCX9VSu`
- Case-sensitive!

---

## 📋 Deployment Checklist

- [ ] Get debug hash from frontend team
- [ ] Get release hash from frontend team
- [ ] Update `.env` file locally
- [ ] Test SMS format locally
- [ ] Update Railway environment variables
- [ ] Deploy to Railway
- [ ] Test on real Android device
- [ ] Test on real iOS device
- [ ] Verify auto-detection works
- [ ] Monitor Twilio logs

---

## 🐛 Troubleshooting

### Android Not Auto-Detecting?

**Check:**
1. ✅ Using **RELEASE** hash in production?
2. ✅ Hash is at the end of message?
3. ✅ Message format is correct?
4. ✅ No extra spaces or line breaks?

### iOS Not Showing OTP?

**Check:**
1. ✅ iOS domain in message?
2. ✅ OTP format is recognizable (4-6 digits)?
3. ✅ Using iOS 12+ device?

### Test Hash is Correct:

```javascript
// Add to authController.js temporarily
console.log('📱 App Hash in SMS:', process.env.ANDROID_APP_HASH);
```

---

## 🔄 Getting Hash from Frontend

### Frontend Team Should Run:

```dart
import 'package:astrologer_app/core/utils/otp_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Print hash (debug or release)
  await OTPHelper.printAppSignature();
  
  runApp(MyApp());
}
```

### They'll see:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 APP HASH SIGNATURE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  FA+9qCX9VSu  ← This is what you need!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📤 Send this hash to your backend team
```

---

## 📊 Expected User Experience

### Before (Manual):
```
1. SMS arrives
2. User switches to Messages
3. User memorizes code
4. User switches back
5. User types code
6. User taps Verify

Time: ~15 seconds
```

### After (Auto-Detection):
```
1. SMS arrives
2. Code auto-fills
3. App verifies

Time: ~2 seconds ⚡
```

---

## 🎯 Summary

### What Changed:
- ✅ SMS format now includes app hash
- ✅ Supports iOS domain for autofill
- ✅ Environment variables for configuration
- ✅ Ready for production deployment

### What You Need:
- 📱 App hash signature (from frontend team)
- ⚙️ Update Railway environment variables
- 🚀 Deploy and test

### Result:
- ⚡ WhatsApp-level OTP experience
- ✨ Zero permissions on Android
- 🎉 One-tap autofill on iOS

---

**Ready to deploy! Just get the hash from frontend team and update Railway variables.** 🚀


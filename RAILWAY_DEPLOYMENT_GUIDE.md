# 🚂 Railway Deployment Guide

## Step 1: Push to GitHub ✅
Run the `push_to_github.bat` file to push your code to GitHub.

## Step 2: Deploy to Railway

### 2.1 Create Railway Account
1. Go to [https://railway.com](https://railway.com)
2. Click **"Sign up with GitHub"**
3. Authorize Railway to access your repositories

### 2.2 Deploy Your Backend
1. In Railway dashboard, click **"New Project"**
2. Select **"Deploy from GitHub repo"**
3. Choose **`jaisonkerala1/astrologer_app`** repository
4. Railway will auto-detect it's a **Node.js** project
5. **IMPORTANT**: Set **Root Directory** to `/backend` in project settings
6. Click **"Deploy"**

### 2.3 Environment Variables
In Railway project dashboard, go to **Variables** tab and add:

```env
PORT=7566
NODE_ENV=production
JWT_SECRET=astrologer_app_super_secret_jwt_key_2024_production_railway
JWT_EXPIRES_IN=7d
TWILIO_ACCOUNT_SID=your_twilio_account_sid_here
TWILIO_AUTH_TOKEN=your_twilio_auth_token_here
TWILIO_PHONE_NUMBER=your_twilio_phone_number_here
CORS_ORIGIN=*
```

### 2.4 Get Your Railway URL
After deployment, Railway will give you a URL like:
`https://astrologer-app-production-xxxx.railway.app`

**Copy this URL - you'll need it for the Flutter app!**

## Step 3: Update Flutter App
Once you have your Railway URL, update the API base URL in:
`lib/core/constants/api_constants.dart`

Change from:
```dart
static const String baseUrl = 'http://192.168.29.99:7566/api';
```

To:
```dart
static const String baseUrl = 'https://your-railway-app.railway.app/api';
```

## Step 4: Rebuild Flutter App
```bash
flutter clean
flutter pub get
flutter build apk --debug
adb install build\app\outputs\flutter-apk\app-debug.apk
```

## 🎉 You're Done!
Your app will now use the Railway backend with:
- ✅ Global HTTPS URL
- ✅ Auto-scaling
- ✅ Real-time monitoring
- ✅ Automatic deployments

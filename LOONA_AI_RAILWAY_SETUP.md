# 🤖 Loona AI - Railway Environment Setup Guide

## Overview
Loona AI has been updated to use a **secure backend proxy** for OpenRouter API calls. The API key is now stored safely on the backend instead of being exposed in the mobile app.

## What Changed?

### ✅ Before (Insecure)
- API key was hardcoded in Flutter app (`loona_ai_service.dart`)
- API key exposed to anyone who decompiles the APK
- Direct calls from mobile app to OpenRouter

### ✅ After (Secure)
- API key stored as environment variable on Railway backend
- Backend proxies requests to OpenRouter
- API key never exposed to users

## 🚂 Railway Environment Variable Setup

### Step 1: Login to Railway
1. Go to [https://railway.app](https://railway.app)
2. Sign in with your account
3. Select your **Astrologer App Backend** project

### Step 2: Add OpenRouter API Key
1. Click on your backend service
2. Go to the **"Variables"** tab
3. Click **"+ New Variable"**
4. Add the following:

```
Variable Name: OPENROUTER_API_KEY
Variable Value: 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
```

5. Click **"Add"** or **"Save"**

### Step 3: Deploy the Changes
Railway will automatically redeploy your backend with the new environment variable.

## 📝 Complete List of Required Environment Variables

Make sure all these variables are set in Railway:

```env
# Server Configuration
PORT=7566
NODE_ENV=production

# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_here
JWT_EXPIRES_IN=7d

# Twilio Configuration
TWILIO_ACCOUNT_SID=your_twilio_account_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_PHONE_NUMBER=your_twilio_phone_number

# CORS Configuration
CORS_ORIGIN=*

# OpenRouter AI Configuration (NEW!)
OPENROUTER_API_KEY=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
```

## 🔄 Backend Changes Made

### 1. New Files Created
- `backend/src/services/openRouterService.js` - Handles OpenRouter API calls
- `backend/src/controllers/loonaController.js` - Controller for Loona endpoints

### 2. Updated Files
- `backend/src/routes/chat.js` - Added new endpoint `/api/chat/loona/generate`
- `backend/package.json` - Added `axios` dependency
- `backend/env.example` - Added `OPENROUTER_API_KEY` example

### 3. New API Endpoint
```
POST /api/chat/loona/generate

Request Body:
{
  "userMessage": "What is Vedic astrology?",
  "conversationHistory": [...],
  "userProfile": {...},
  "settings": {...}
}

Response:
{
  "success": true,
  "data": {
    "response": "AI response text here..."
  }
}
```

## 📱 Flutter App Changes Made

### 1. Updated Files
- `lib/features/chat/services/loona_ai_service.dart` - Now calls backend instead of OpenRouter
- `lib/core/constants/api_constants.dart` - Added `loonaGenerate` endpoint

### 2. Changes Summary
- Removed hardcoded API key
- Updated `generateResponse()` to call backend
- Simplified message preparation (backend handles context)

## 🧪 Testing After Deployment

### 1. Push Backend Changes to GitHub
```bash
cd backend
git add .
git commit -m "Add Loona AI backend proxy with OpenRouter"
git push origin main
```

### 2. Railway Auto-Deploy
Railway will automatically detect the changes and redeploy (takes ~2-3 minutes)

### 3. Install Backend Dependencies
Railway will automatically run `npm install` which will install the new `axios` dependency

### 4. Test the App
1. Rebuild the Flutter app:
```bash
flutter clean
flutter pub get
flutter build apk
flutter install
```

2. Open the app and go to Loona AI chat
3. Send a test message: "Hello Loona, what can you help me with?"
4. You should get an AI response

## 🔍 Troubleshooting

### Issue: "OpenRouter API key is not configured"
**Solution**: Make sure `OPENROUTER_API_KEY` is added in Railway variables

### Issue: "Failed to get response from Loona AI"
**Solution**: 
1. Check Railway logs for errors
2. Verify the API key is correct
3. Check if OpenRouter API is working at [openrouter.ai](https://openrouter.ai)

### Issue: App shows fallback response
**Solution**: 
1. Check backend logs in Railway
2. Verify backend URL in `lib/core/constants/api_constants.dart`
3. Make sure backend is deployed and running

## 📊 Monitoring

### Railway Dashboard
- Monitor API calls in Railway logs
- Check for any error messages
- View response times

### OpenRouter Dashboard
- Track API usage at [https://openrouter.ai/activity](https://openrouter.ai/activity)
- Monitor credit balance
- View request statistics

## 💰 Cost Management

**OpenRouter Pricing:**
- Model: `anthropic/claude-3-haiku`
- Cost: ~$0.25 per million input tokens
- Cost: ~$1.25 per million output tokens

**Typical Usage:**
- Average conversation: ~500 tokens
- 1000 conversations ≈ $0.50

**Tips to Reduce Costs:**
1. Limit conversation history to 10 messages
2. Set `max_tokens: 800` (already configured)
3. Monitor usage regularly

## 🔐 Security Best Practices

✅ **Do:**
- Keep API key in Railway environment variables
- Rotate API key regularly
- Monitor usage for suspicious activity
- Use HTTPS for all API calls

❌ **Don't:**
- Never commit API keys to Git
- Never hardcode keys in Flutter app
- Never share API keys publicly
- Never use same key across projects

## 🎉 Summary

You've successfully secured Loona AI by:
1. ✅ Moving API key to backend
2. ✅ Creating backend proxy endpoint
3. ✅ Updating Flutter app to use backend
4. ✅ Adding Railway environment variable

Loona AI is now ready to provide secure, intelligent support to your astrologer app users!

---

**Need Help?** Check Railway logs or OpenRouter documentation for troubleshooting.


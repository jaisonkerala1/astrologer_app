# 🔴 Live Stream Testing Guide

This guide helps you test and verify that live streaming is working correctly in your astrologer app.

## 🚀 Quick Testing Methods

### 1. **Admin Dashboard (Easiest Method)**
- **URL**: `https://astrologerapp-production.up.railway.app/admin-dashboard.html`
- **What it shows**: Real-time view of all active streams, viewer counts, and server status
- **How to use**: 
  1. Open the URL in your browser
  2. Start a live stream from your mobile app
  3. Watch the dashboard update in real-time
  4. Auto-refreshes every 10 seconds

### 2. **API Endpoints for Testing**

#### Check Server Health
```bash
curl https://astrologerapp-production.up.railway.app/api/health
```

#### Get Live Streams Status
```bash
curl https://astrologerapp-production.up.railway.app/api/live-streams/status
```

#### Get Detailed Admin Data
```bash
curl https://astrologerapp-production.up.railway.app/api/admin/live-streams
```

### 3. **Automated Testing Script**
Run the test script to verify all endpoints:
```bash
cd backend
node test-live-streams.js
```

## 🔍 How to Verify Live Streams Are Working

### Step 1: Check Server Logs
1. Go to your Railway dashboard
2. Check the logs for these messages when starting a stream:
   ```
   🟢 Live stream started: stream_1234567890_abc123 by Your Name
   📊 Stream details:
     - ID: stream_1234567890_abc123
     - Astrologer: Your Name (user_id)
     - Title: Your Stream Title
     - Channel: live_user_id_1234567890
     - Status: live
   📈 Active streams count: 1
   📺 All active streams:
     - stream_1234567890_abc123: Your Stream Title by Your Name (live)
   ```

### Step 2: Test Stream Creation
1. Start a live stream from your mobile app
2. Check the admin dashboard immediately
3. You should see:
   - Stream appears in the table
   - Status shows "LIVE"
   - Viewer count starts at 0
   - Duration starts counting

### Step 3: Test Stream Viewing
1. Open the admin dashboard in another browser tab
2. Start a stream from the app
3. Try to join the stream from another device or browser
4. Check if viewer count increases

## 🐛 Common Issues and Solutions

### Issue: Stream doesn't appear in admin dashboard
**Possible causes:**
- WebSocket connection failed
- Backend API not responding
- Stream not properly created

**Solutions:**
1. Check server logs for errors
2. Verify API endpoints are responding
3. Check WebSocket connection in browser dev tools

### Issue: Stream shows but viewer count doesn't update
**Possible causes:**
- Agora channel not properly joined
- WebSocket not broadcasting updates
- Frontend not updating stats

**Solutions:**
1. Check Agora SDK logs in mobile app
2. Verify WebSocket messages in browser dev tools
3. Check if stats update endpoint is working

### Issue: Stream starts but immediately ends
**Possible causes:**
- Agora token issues
- Permission problems
- Network connectivity issues

**Solutions:**
1. Check camera/microphone permissions
2. Verify Agora configuration
3. Check network connectivity

## 📱 Mobile App Testing

### Debug Information in App
The app now includes comprehensive logging. Look for these debug messages:

**When starting a stream:**
```
🔐 Requesting camera and microphone permissions...
✅ Permissions granted successfully
📡 Notifying backend about stream start...
📊 Stream details:
  - Astrologer ID: user_123
  - Astrologer Name: Your Name
  - Title: Your Stream Title
  - Channel: live_user_123_1234567890
✅ Backend notified successfully
🎬 Joining Agora channel as broadcaster...
✅ Successfully joined Agora channel as broadcaster
```

**When joining a stream:**
```
🔍 Looking for stream: stream_1234567890_abc123
📊 Found 1 active streams
✅ Found stream: Your Stream Title by Your Name
🎬 Joining channel: live_user_123_1234567890 as audience
✅ Successfully joined Agora channel
```

## 🔧 Backend Monitoring

### Real-time Monitoring
- **Admin Dashboard**: `https://astrologerapp-production.up.railway.app/admin-dashboard.html`
- **API Status**: `https://astrologerapp-production.up.railway.app/api/live-streams/status`
- **Server Health**: `https://astrologerapp-production.up.railway.app/api/health`

### Key Metrics to Watch
1. **Active Streams Count**: Should increase when stream starts
2. **Viewer Count**: Should update when users join/leave
3. **Server Uptime**: Should be stable
4. **Memory Usage**: Should not spike excessively

## 🚨 Troubleshooting Checklist

- [ ] Server is running and accessible
- [ ] WebSocket connection is established
- [ ] Mobile app has camera/microphone permissions
- [ ] Agora SDK is properly initialized
- [ ] Backend API endpoints are responding
- [ ] Stream appears in admin dashboard
- [ ] Viewer count updates correctly
- [ ] Stream can be joined by other users

## 📞 Support

If you're still having issues:
1. Check the Railway logs for error messages
2. Run the test script to verify API endpoints
3. Use the admin dashboard to monitor stream status
4. Check mobile app debug logs for Agora SDK issues

The admin dashboard is the easiest way to verify if your streams are actually starting and being tracked by the backend!

# Live Streams API for Astrologer App

This backend API provides real-time live streaming functionality for the Astrologer App, including WebSocket support for cross-device synchronization.

## 🚀 Features

- **Real-time Live Streams**: Start, end, and manage live streams
- **WebSocket Support**: Real-time updates across all connected devices
- **Cross-Device Sync**: Streams appear instantly on all devices
- **RESTful API**: Standard HTTP endpoints for stream management
- **Health Monitoring**: Built-in health check endpoints

## 📋 API Endpoints

### Live Stream Management
- `POST /api/live-streams/start` - Start a new live stream
- `PUT /api/live-streams/:id/end` - End a live stream
- `GET /api/live-streams/active` - Get all active streams
- `GET /api/live-streams/:id` - Get specific stream details
- `PUT /api/live-streams/:id/stats` - Update stream statistics

### WebSocket
- `ws://your-domain/ws/live-streams` - Real-time stream updates

### Health Check
- `GET /api/health` - API health status

## 🛠️ Setup for Railway Deployment

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Environment Variables
Create a `.env` file (optional for basic setup):
```env
PORT=3001
NODE_ENV=production
```

### 3. Deploy to Railway

#### Option A: Using Railway CLI
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login to Railway
railway login

# Initialize project
railway init

# Deploy
railway up
```

#### Option B: Using Railway Dashboard
1. Go to [Railway.app](https://railway.app)
2. Create a new project
3. Connect your GitHub repository
4. Select the `backend` folder
5. Railway will automatically detect Node.js and deploy

### 4. Configure WebSocket URL
After deployment, update your Flutter app with the Railway URL:
- Production: `wss://your-app-name.up.railway.app/ws/live-streams`
- API Base: `https://your-app-name.up.railway.app/api`

## 🔧 Development Setup

### Local Development
```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Or start production server
npm start
```

### Testing the API
```bash
# Health check
curl https://your-app-name.up.railway.app/api/health

# Get active streams
curl https://your-app-name.up.railway.app/api/live-streams/active
```

## 📱 Flutter Integration

The Flutter app will automatically connect to:
- **Development**: `ws://localhost:3001/ws/live-streams`
- **Production**: `wss://your-app-name.up.railway.app/ws/live-streams`

## 🔄 Real-time Updates

The WebSocket server broadcasts the following events:

### Stream Started
```json
{
  "type": "stream_started",
  "data": {
    "id": "stream_123",
    "astrologerName": "Dr. Sarah",
    "title": "Daily Tarot Reading",
    "viewerCount": 0,
    "status": "live"
  }
}
```

### Stream Ended
```json
{
  "type": "stream_ended",
  "data": {
    "id": "stream_123",
    "endedAt": "2024-01-01T12:00:00Z"
  }
}
```

### Stats Updated
```json
{
  "type": "stream_stats_updated",
  "data": {
    "id": "stream_123",
    "viewerCount": 45,
    "likes": 23,
    "comments": 8
  }
}
```

## 🚨 Troubleshooting

### Common Issues

1. **WebSocket Connection Failed**
   - Check if Railway supports WebSockets
   - Verify the WebSocket URL format
   - Check firewall settings

2. **API Not Responding**
   - Check Railway deployment logs
   - Verify environment variables
   - Test health endpoint

3. **CORS Issues**
   - The API includes CORS middleware
   - Check if your Flutter app URL is allowed

### Logs
Check Railway deployment logs for debugging:
```bash
railway logs
```

## 📊 Monitoring

The API provides health check endpoint for monitoring:
- `GET /api/health` - Returns active streams count and connected clients

## 🔒 Security Considerations

For production deployment:
1. Add authentication middleware
2. Implement rate limiting
3. Add input validation
4. Use HTTPS/WSS only
5. Add CORS restrictions

## 📈 Scaling

For high-traffic scenarios:
1. Use Redis for stream storage
2. Implement load balancing
3. Add database persistence
4. Use message queues for WebSocket scaling

## 🤝 Support

For issues or questions:
1. Check Railway deployment logs
2. Test API endpoints manually
3. Verify WebSocket connection
4. Check Flutter app logs
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const http = require('http');
const WebSocket = require('ws');
const crypto = require('crypto');
const path = require('path');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const PORT = 7566; // Force port 7566
console.log('🚀 Server starting - force redeploy 2025-09-20 v3 with OTP ObjectId fix');

// Security middleware
app.use(helmet());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use(limiter);

// CORS configuration
app.use(cors({
  origin: [
    process.env.CORS_ORIGIN || 'http://localhost:3000',
    'http://10.0.2.2:7566',
    'http://localhost:7566',
    'http://127.0.0.1:7566'
  ],
  credentials: true
}));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Serve static files (uploaded images)
app.use('/uploads', express.static('uploads'));

// Serve admin dashboard
app.get('/admin-dashboard.html', (req, res) => {
  res.sendFile(path.join(__dirname, '../admin-dashboard.html'));
});

// Serve admin dashboard JavaScript
app.get('/admin-dashboard.js', (req, res) => {
  res.sendFile(path.join(__dirname, '../admin-dashboard.js'));
});

// Serve live viewer page
app.get('/live-viewer.html', (req, res) => {
  res.sendFile(path.join(__dirname, '../live-viewer.html'));
});

// Database connection
const connectDB = async () => {
  try {
    if (!process.env.MONGODB_URI) {
      throw new Error('MONGODB_URI environment variable is not set');
    }
    
    console.log('Attempting to connect to MongoDB...');
    
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 30000,
      socketTimeoutMS: 45000,
      maxPoolSize: 10,
      bufferCommands: false,
      bufferMaxEntries: 0,
    });
    
    console.log('Connected to MongoDB successfully');
    
  } catch (error) {
    console.error('MongoDB connection error:', error.message);
    console.error('Server will retry MongoDB connection in background...');
    
    // Retry connection every 30 seconds
    setInterval(async () => {
      try {
        if (mongoose.connection.readyState !== 1) {
          await mongoose.connect(process.env.MONGODB_URI, {
            useNewUrlParser: true,
            useUnifiedTopology: true,
            serverSelectionTimeoutMS: 10000,
            socketTimeoutMS: 20000,
          });
          console.log('MongoDB reconnected successfully');
        }
      } catch (retryError) {
        console.log('MongoDB retry failed, will try again in 30 seconds...');
      }
    }, 30000);
  }
};

// Connect to database
connectDB();

// Live Streaming WebSocket Server
const wss = new WebSocket.Server({ server });
const connectedClients = new Set();
const activeStreams = new Map();

// WebSocket connection handling
wss.on('connection', (ws) => {
  console.log('🔌 New WebSocket client connected for live streaming');
  connectedClients.add(ws);

  // Send current active streams to new client
  ws.send(JSON.stringify({
    type: 'active_streams',
    data: Array.from(activeStreams.values())
  }));

  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      console.log('📨 WebSocket message received:', data.type);
      
      // Handle different message types
      switch (data.type) {
        case 'request_active_streams':
          // Send current active streams to client
          const activeStreamsList = Array.from(activeStreams.values());
          ws.send(JSON.stringify({
            type: 'active_streams',
            data: activeStreamsList
          }));
          console.log(`📡 Sent ${activeStreamsList.length} active streams to client`);
          break;
        case 'join_stream':
          // Client wants to join a specific stream
          break;
        case 'leave_stream':
          // Client wants to leave a stream
          break;
        default:
          console.log('⚠️ Unknown message type:', data.type);
      }
    } catch (error) {
      console.error('❌ Error parsing WebSocket message:', error);
    }
  });

  ws.on('close', () => {
    console.log('🔌 WebSocket client disconnected');
    connectedClients.delete(ws);
  });

  ws.on('error', (error) => {
    console.error('❌ WebSocket error:', error);
    connectedClients.delete(ws);
  });
});

// Broadcast to all connected clients
function broadcastToClients(data) {
  const message = JSON.stringify(data);
  connectedClients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });
}

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Live streams health check and monitoring
app.get('/api/live-streams/status', (req, res) => {
  try {
    const activeStreamsList = Array.from(activeStreams.values());
    
    res.json({
      success: true,
      data: {
        totalActiveStreams: activeStreamsList.length,
        streams: activeStreamsList.map(stream => ({
          id: stream.id,
          astrologerId: stream.astrologerId,
          astrologerName: stream.astrologerName,
          title: stream.title,
          status: stream.status,
          channelName: stream.agoraChannelName,
          viewerCount: stream.viewerCount,
          startedAt: stream.startedAt,
          duration: Math.floor((Date.now() - new Date(stream.startedAt).getTime()) / 1000)
        })),
        serverTime: new Date().toISOString(),
        uptime: process.uptime()
      }
    });
  } catch (error) {
    console.error('❌ Error getting live streams status:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Admin endpoint to get detailed stream information
app.get('/api/admin/live-streams', (req, res) => {
  try {
    const activeStreamsList = Array.from(activeStreams.values());
    
    res.json({
      success: true,
      data: {
        totalActiveStreams: activeStreamsList.length,
        streams: activeStreamsList,
        serverInfo: {
          uptime: process.uptime(),
          memoryUsage: process.memoryUsage(),
          timestamp: new Date().toISOString()
        }
      }
    });
  } catch (error) {
    console.error('❌ Error getting admin live streams data:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/dashboard', require('./routes/dashboard'));
app.use('/api/profile', require('./routes/profile'));
app.use('/api/consultation', require('./routes/consultation'));
app.use('/api/chat', require('./routes/chat'));
app.use('/api/reviews', require('./routes/reviews'));
app.use('/api/seed', require('./routes/seed'));

// Live Streaming API Routes
// Start a live stream
app.post('/api/live-streams/start', (req, res) => {
  try {
    const {
      astrologerId,
      astrologerName,
      astrologerProfilePicture,
      title,
      description,
      category,
      quality,
      isPrivate,
      tags,
      agoraChannelName,
      agoraToken
    } = req.body;

    // Validate required fields
    if (!astrologerId || !title || !agoraChannelName) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields'
      });
    }

    // Check if astrologer already has an active stream and end it automatically
    const existingStream = Array.from(activeStreams.values()).find(
      stream => stream.astrologerId === astrologerId && stream.status === 'live'
    );
    
    if (existingStream) {
      console.log(`🔄 Ending existing stream: ${existingStream.id} before starting new one`);
      existingStream.status = 'ended';
      existingStream.endedAt = new Date().toISOString();
      
      // Broadcast stream ended event
      broadcastToClients({
        type: 'stream_ended',
        data: existingStream
      });
    }

    // Generate unique stream ID
    const streamId = `stream_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // Create stream object
    const stream = {
      id: streamId,
      astrologerId,
      astrologerName: astrologerName || 'Unknown Astrologer',
      astrologerProfilePicture,
      title,
      description,
      category: category || 'general',
      quality: quality || 'medium',
      status: 'live',
      isPrivate: isPrivate || false,
      tags: tags || [],
      agoraChannelName,
      agoraToken,
      viewerCount: 0,
      totalViewers: 0,
      likes: 0,
      comments: 0,
      startedAt: new Date().toISOString(),
      endedAt: null
    };

    // Store the stream
    activeStreams.set(streamId, stream);

    // Broadcast to all clients
    broadcastToClients({
      type: 'stream_started',
      data: stream
    });

    console.log(`🟢 Live stream started: ${streamId} by ${astrologerName}`);
    console.log(`📊 Stream details:`);
    console.log(`  - ID: ${streamId}`);
    console.log(`  - Astrologer: ${astrologerName} (${astrologerId})`);
    console.log(`  - Title: ${title}`);
    console.log(`  - Channel: ${agoraChannelName}`);
    console.log(`  - Status: ${stream.status}`);
    console.log(`  - Quality: ${quality}`);
    console.log(`  - Private: ${isPrivate}`);
    console.log(`  - Tags: ${tags.join(', ')}`);
    console.log(`📈 Active streams count: ${activeStreams.size}`);
    
    // Log all active streams for debugging
    console.log(`📺 All active streams:`);
    activeStreams.forEach((activeStream, id) => {
      console.log(`  - ${id}: ${activeStream.title} by ${activeStream.astrologerName} (${activeStream.status})`);
    });

    res.json({
      success: true,
      data: stream
    });

  } catch (error) {
    console.error('❌ Error starting live stream:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Generate Agora token
app.post('/api/agora/token', (req, res) => {
  try {
    const { channelName, uid, role = 'audience' } = req.body;

    if (!channelName) {
      return res.status(400).json({
        success: false,
        message: 'Channel name is required'
      });
    }

    // For development, we'll disable token authentication by returning empty token
    // This works when Agora App is configured for "Testing Mode" (no certificate)
    const token = '';
    const actualUid = uid || Math.floor(Math.random() * 100000);
    const expirationTime = Math.floor(Date.now() / 1000) + (24 * 3600); // 24 hours

    console.log(`🎫 Generated empty token for channel: ${channelName}, UID: ${actualUid}, role: ${role}`);
    console.log(`🔧 Note: Using empty token for testing. Configure Agora App for "Testing Mode" if needed.`);

    res.json({
      success: true,
      data: {
        token,
        channelName,
        uid: actualUid,
        expirationTime,
        appId: '6358473261094f98be1fea84042b1fcf'
      }
    });

  } catch (error) {
    console.error('❌ Error generating token:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// End a live stream
app.put('/api/live-streams/:id/end', (req, res) => {
  try {
    const { id } = req.params;

    if (!activeStreams.has(id)) {
      return res.status(404).json({
        success: false,
        message: 'Stream not found'
      });
    }

    const stream = activeStreams.get(id);
    stream.status = 'ended';
    stream.endedAt = new Date().toISOString();

    // Remove from active streams
    activeStreams.delete(id);

    // Broadcast to all clients
    broadcastToClients({
      type: 'stream_ended',
      data: { id, endedAt: stream.endedAt }
    });

    console.log(`🔴 Live stream ended: ${id}`);

    res.json({
      success: true,
      data: stream
    });

  } catch (error) {
    console.error('❌ Error ending live stream:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get all active streams
app.get('/api/live-streams/active', (req, res) => {
  try {
    const streams = Array.from(activeStreams.values());
    
    res.json({
      success: true,
      data: streams
    });

  } catch (error) {
    console.error('❌ Error getting active streams:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get specific stream details
app.get('/api/live-streams/:id', (req, res) => {
  try {
    const { id } = req.params;
    const stream = activeStreams.get(id);

    if (!stream) {
      return res.status(404).json({
        success: false,
        message: 'Stream not found'
      });
    }

    res.json({
      success: true,
      data: stream
    });

  } catch (error) {
    console.error('❌ Error getting stream details:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Update stream stats
app.put('/api/live-streams/:id/stats', (req, res) => {
  try {
    const { id } = req.params;
    const { viewerCount, likes, comments } = req.body;

    if (!activeStreams.has(id)) {
      return res.status(404).json({
        success: false,
        message: 'Stream not found'
      });
    }

    const stream = activeStreams.get(id);
    
    if (viewerCount !== undefined) stream.viewerCount = viewerCount;
    if (likes !== undefined) stream.likes = likes;
    if (comments !== undefined) stream.comments = comments;

    // Broadcast updated stats
    broadcastToClients({
      type: 'stream_stats_updated',
      data: {
        id,
        viewerCount: stream.viewerCount,
        likes: stream.likes,
        comments: stream.comments
      }
    });

    res.json({
      success: true,
      data: stream
    });

  } catch (error) {
    console.error('❌ Error updating stream stats:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});



// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Something went wrong!',
    error: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

// Start server
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
  console.log(`🔌 WebSocket server: ws://localhost:${PORT}/ws/live-streams`);
  console.log(`📡 Live streams API: http://localhost:${PORT}/api/live-streams/active`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`Reviews API enabled at ${new Date().toISOString()}`);
});

module.exports = app;






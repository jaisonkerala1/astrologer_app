const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const http = require('http');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 7566;
console.log('🚀 Server starting - SOCKET.IO REALTIME UPDATE 2025-12-13');

// Create HTTP server for Socket.IO
const httpServer = http.createServer(app);

// Initialize Socket.IO
let io;
try {
  const { initSocketIO } = require('./socket');
  io = initSocketIO(httpServer);
  // Make io accessible to routes via app.get('io')
  app.set('io', io);
  console.log('✅ Socket.IO initialized');
} catch (error) {
  console.error('❌ Failed to initialize Socket.IO:', error.message);
}

// Security middleware
app.use(helmet());

// Rate limiting - Increased limits for mobile app usage
const limiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute window
  max: 200, // 200 requests per minute (much more lenient for mobile apps)
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
  // Skip rate limiting for certain paths that are called frequently
  skip: (req) => {
    const skipPaths = ['/api/live/active', '/health', '/api/dashboard/stats'];
    return skipPaths.some(path => req.path.startsWith(path));
  }
});
app.use(limiter);

// CORS configuration
app.use(cors({
  origin: function(origin, callback) {
    // Allow requests with no origin (like mobile apps or curl)
    if (!origin) return callback(null, true);
    
    // If CORS_ORIGIN is '*', allow all origins
    if (process.env.CORS_ORIGIN === '*') {
      return callback(null, true);
    }
    
    // Allow localhost origins
    if (origin.startsWith('http://localhost') || 
        origin.startsWith('http://127.0.0.1') ||
        origin.startsWith('http://10.0.2.2')) {
      return callback(null, true);
    }
    
    // Check if origin matches CORS_ORIGIN (supports comma-separated list)
    const allowedOrigins = (process.env.CORS_ORIGIN || 'http://localhost:3000').split(',').map(o => o.trim());
    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    
    // Allow vercel.app domains
    if (origin.includes('vercel.app')) {
      return callback(null, true);
    }
    
    callback(new Error('Not allowed by CORS'));
  },
  credentials: true
}));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Serve static files with CORS headers
app.use('/uploads', (req, res, next) => {
  // Set CORS headers for static files
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  res.header('Cross-Origin-Resource-Policy', 'cross-origin');
  next();
}, express.static('uploads'));

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
    });
    
    console.log('Connected to MongoDB successfully');
    
  } catch (error) {
    console.error('MongoDB connection error:', error.message);
    console.error('Server will retry MongoDB connection in background...');
    
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

connectDB();

// Health check endpoint
app.get('/api/health', (req, res) => {
  const { roomManager } = require('./socket');
  const socketStats = roomManager ? roomManager.getStats() : { error: 'Socket not initialized' };
  
  res.status(200).json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    socket: {
      connected: io ? true : false,
      ...socketStats,
    }
  });
});

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/dashboard', require('./routes/dashboard'));
app.use('/api/profile', require('./routes/profile'));
app.use('/api/consultation', require('./routes/consultation'));
app.use('/api/chat', require('./routes/chat'));
app.use('/api/reviews', require('./routes/reviews'));
app.use('/api/seed', require('./routes/seed'));
app.use('/api/migration', require('./routes/migration'));

// Admin routes
try {
  const adminRoutes = require('./routes/admin');
  app.use('/api/admin', adminRoutes);
  console.log('✅ Admin routes loaded');
} catch (error) {
  console.error('❌ Failed to load admin routes:', error.message);
  app.use('/api/admin', (req, res) => {
    res.status(500).json({
      success: false,
      message: 'Admin routes failed to load',
      error: error.message
    });
  });
}

// Live streaming routes
try {
  const liveRoutes = require('./routes/live');
  app.use('/api/live', liveRoutes);
  console.log('✅ Live streaming routes loaded');
} catch (error) {
  console.error('❌ Failed to load live routes:', error.message);
  app.use('/api/live', (req, res) => {
    res.status(500).json({
      success: false,
      message: 'Live routes failed to load',
      error: error.message
    });
  });
}

// Discussion routes
try {
  const discussionRoutes = require('./routes/discussion');
  app.use('/api/discussion', discussionRoutes);
  console.log('✅ Discussion routes loaded');
} catch (error) {
  console.error('❌ Failed to load discussion routes:', error.message);
  app.use('/api/discussion', (req, res) => {
    res.status(500).json({
      success: false,
      message: 'Discussion routes failed to load',
      error: error.message
    });
  });
}

// Heal/Services routes
try {
  const servicesRoutes = require('./routes/services');
  app.use('/api/services', servicesRoutes);
  console.log('✅ Services routes loaded');
} catch (error) {
  console.error('❌ Failed to load services routes:', error.message);
  app.use('/api/services', (req, res) => {
    res.status(500).json({
      success: false,
      message: 'Services routes failed to load',
      error: error.message
    });
  });
}

// Service Requests routes
try {
  const serviceRequestsRoutes = require('./routes/serviceRequests');
  app.use('/api/service-requests', serviceRequestsRoutes);
  console.log('✅ Service Requests routes loaded');
} catch (error) {
  console.error('❌ Failed to load service requests routes:', error.message);
  app.use('/api/service-requests', (req, res) => {
    res.status(500).json({
      success: false,
      message: 'Service Requests routes failed to load',
      error: error.message
    });
  });
}

// FCM routes (push notifications)
try {
  const fcmRoutes = require('./routes/fcm');
  app.use('/api/fcm', fcmRoutes);
  console.log('✅ FCM routes loaded');
} catch (error) {
  console.error('❌ Failed to load FCM routes:', error.message);
  app.use('/api/fcm', (req, res) => {
    res.status(500).json({
      success: false,
      message: 'FCM routes failed to load',
      error: error.message
    });
  });
}

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

// Start server with HTTP server (for Socket.IO)
httpServer.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Server accessible at: http://localhost:${PORT}`);
  console.log(`WebSocket enabled at: ws://localhost:${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  
  startStreamHealthCheck();
});

/**
 * Background job: Clean up dead streams
 */
function startStreamHealthCheck() {
  const LiveStream = require('./models/LiveStream');
  
  console.log('🩺 Starting stream health check background job');
  
  setInterval(async () => {
    try {
      const now = new Date();
      const deadThreshold = new Date(now.getTime() - 60 * 1000);
      
      const deadStreams = await LiveStream.find({
        isLive: true,
        lastHeartbeat: { $lt: deadThreshold }
      });
      
      if (deadStreams.length > 0) {
        console.log(`💀 Found ${deadStreams.length} dead stream(s) - Auto-ending...`);
        
        for (const stream of deadStreams) {
          const timeSinceHeartbeat = Math.floor((now - stream.lastHeartbeat) / 1000);
          console.log(`  ⚰️  Stream ${stream._id} (${stream.astrologerName}) - Last heartbeat: ${timeSinceHeartbeat}s ago`);
          
          stream.isLive = false;
          stream.endedAt = now;
          await stream.save();
          
          // Notify viewers via Socket.IO
          if (io) {
            const roomId = `live:${stream._id}`;
            io.to(roomId).emit('live:end', {
              streamId: stream._id.toString(),
              message: 'Stream has ended',
              reason: 'timeout',
              timestamp: Date.now(),
            });
          }
        }
        
        console.log(`✅ Auto-ended ${deadStreams.length} dead stream(s)`);
      }
      
    } catch (error) {
      console.error('❌ Error in stream health check:', error);
    }
  }, 60 * 1000);
}

// Export for testing
module.exports = { app, io };

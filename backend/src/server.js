const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const app = express();
const PORT = 7566; // Force port 7566
console.log('🚀 Server starting - LIVE STREAMING UPDATE 2025-12-12 v3');

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
  origin: function(origin, callback) {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    
    // Allow all localhost/127.0.0.1 origins regardless of port
    if (origin.startsWith('http://localhost') || 
        origin.startsWith('http://127.0.0.1') ||
        origin.startsWith('http://10.0.2.2') ||
        origin === (process.env.CORS_ORIGIN || 'http://localhost:3000')) {
      return callback(null, true);
    }
    
    // Reject all other origins
    callback(new Error('Not allowed by CORS'));
  },
  credentials: true
}));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Serve static files (uploaded images)
app.use('/uploads', express.static('uploads'));

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

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
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

// Live streaming routes
try {
  const liveRoutes = require('./routes/live');
  app.use('/api/live', liveRoutes);
  console.log('✅ Live streaming routes loaded');
} catch (error) {
  console.error('❌ Failed to load live routes:', error.message);
  // Fallback route to show error
  app.use('/api/live', (req, res) => {
    res.status(500).json({
      success: false,
      message: 'Live routes failed to load',
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

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Server accessible at: http://localhost:${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`Reviews API enabled at ${new Date().toISOString()}`);
  
  // Start background job for cleaning up dead streams
  startStreamHealthCheck();
});

/**
 * Background job: Clean up dead streams (no heartbeat for 60+ seconds)
 * Runs every 60 seconds
 */
function startStreamHealthCheck() {
  const LiveStream = require('./models/LiveStream');
  
  console.log('🩺 Starting stream health check background job');
  
  setInterval(async () => {
    try {
      const now = new Date();
      const deadThreshold = new Date(now.getTime() - 60 * 1000); // 60 seconds ago
      
      // Find streams that are marked as live but haven't sent heartbeat in 60s
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
        }
        
        console.log(`✅ Auto-ended ${deadStreams.length} dead stream(s)`);
      }
      
    } catch (error) {
      console.error('❌ Error in stream health check:', error);
    }
  }, 60 * 1000); // Run every 60 seconds
}

module.exports = app;






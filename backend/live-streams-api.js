// Live Streams API for Railway Backend
// This file should be added to your existing Railway backend

const express = require('express');
const WebSocket = require('ws');
const http = require('http');
const cors = require('cors');

const app = express();
const server = http.createServer(app);

// WebSocket server for real-time updates
const wss = new WebSocket.Server({ server });

// Middleware
app.use(cors());
app.use(express.json());

// In-memory storage for live streams (in production, use Redis or database)
const activeStreams = new Map();
const connectedClients = new Set();

// WebSocket connection handling
wss.on('connection', (ws) => {
  console.log('New WebSocket client connected');
  connectedClients.add(ws);

  // Send current active streams to new client
  ws.send(JSON.stringify({
    type: 'active_streams',
    data: Array.from(activeStreams.values())
  }));

  ws.on('close', () => {
    console.log('WebSocket client disconnected');
    connectedClients.delete(ws);
  });

  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
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

// API Routes

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

    console.log(`Live stream started: ${streamId} by ${astrologerName}`);

    res.json({
      success: true,
      data: stream
    });

  } catch (error) {
    console.error('Error starting live stream:', error);
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

    console.log(`Live stream ended: ${id}`);

    res.json({
      success: true,
      data: stream
    });

  } catch (error) {
    console.error('Error ending live stream:', error);
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
    console.error('Error getting active streams:', error);
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
    console.error('Error getting stream details:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Update stream stats (viewer count, likes, etc.)
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
    console.error('Error updating stream stats:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'Live Streams API is running',
    activeStreams: activeStreams.size,
    connectedClients: connectedClients.size
  });
});

const PORT = process.env.PORT || 3001;

server.listen(PORT, () => {
  console.log(`Live Streams API running on port ${PORT}`);
  console.log(`WebSocket server running on ws://localhost:${PORT}`);
});

module.exports = app;

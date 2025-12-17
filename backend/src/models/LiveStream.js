const mongoose = require('mongoose');

const liveStreamSchema = new mongoose.Schema({
  astrologerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Astrologer',
    required: true,
    index: true
  },
  astrologerName: {
    type: String,
    required: true
  },
  astrologerProfilePicture: String,
  astrologerSpecialty: String,
  title: {
    type: String,
    default: 'Live Session'
  },
  description: {
    type: String,
    default: ''
  },
  category: {
    type: String,
    enum: ['general', 'astrology', 'healing', 'meditation', 'tarot', 'numerology', 'palmistry', 'spiritual'],
    default: 'astrology'
  },
  tags: [{
    type: String
  }],
  
  // Agora specific fields
  agoraChannelName: {
    type: String,
    required: true,
    unique: true
  },
  
  // Stream status
  isLive: {
    type: Boolean,
    default: true,
    index: true
  },
  startedAt: {
    type: Date,
    default: Date.now
  },
  endedAt: Date,
  
  // Heartbeat for detecting dead streams
  lastHeartbeat: {
    type: Date,
    default: Date.now
  },
  
  // Metrics
  viewerCount: {
    type: Number,
    default: 0
  },
  peakViewerCount: {
    type: Number,
    default: 0
  },
  totalViews: {
    type: Number,
    default: 0
  },
  likes: {
    type: Number,
    default: 0
  },
  
  // Stream quality
  thumbnailUrl: String,
  
  // Admin controls & moderation
  isBanned: {
    type: Boolean,
    default: false
  },
  bannedReason: String,
  bannedAt: Date,
  warnings: [{
    message: String,
    timestamp: Date
  }],
  bannedViewers: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    reason: String,
    bannedAt: Date
  }]
  
}, {
  timestamps: true
});

// Index for finding active streams
liveStreamSchema.index({ isLive: 1, startedAt: -1 });

module.exports = mongoose.model('LiveStream', liveStreamSchema);


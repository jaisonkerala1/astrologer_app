/**
 * Call Model
 * Voice and video calls between admin-astrologer or user-astrologer
 */

const mongoose = require('mongoose');

const callSchema = new mongoose.Schema({
  callerId: { 
    type: String, 
    required: true,
    index: true
  },
  callerType: { 
    type: String, 
    required: true, 
    enum: ['user', 'astrologer', 'admin'] 
  },
  callerName: String,
  callerAvatar: String,
  recipientId: { 
    type: String, 
    required: true,
    index: true
  },
  recipientType: { 
    type: String, 
    required: true, 
    enum: ['user', 'astrologer', 'admin'] 
  },
  recipientName: String,
  recipientAvatar: String,
  callType: { 
    type: String, 
    required: true, 
    enum: ['voice', 'video'] 
  },
  channelName: { 
    type: String, 
    required: true,
    unique: true,
    index: true
  },
  agoraToken: String,
  agoraUid: Number,
  status: { 
    type: String, 
    default: 'initiated', 
    enum: ['initiated', 'ringing', 'accepted', 'rejected', 'connected', 'ended', 'missed', 'failed', 'cancelled'] 
  },
  startedAt: { 
    type: Date, 
    default: Date.now,
    index: true
  },
  ringingAt: Date,
  acceptedAt: Date,
  connectedAt: Date,
  endedAt: Date,
  duration: {
    type: Number,
    default: 0 // in seconds
  },
  endReason: {
    type: String,
    enum: ['completed', 'declined', 'missed', 'cancelled', 'network_error', 'timeout']
  },
  endedBy: String, // userId who ended the call
  endedByType: String, // user type who ended
  recording: {
    isEnabled: Boolean,
    recordingId: String,
    resourceId: String,
    sid: String,
    recordingUrl: String
  },
  quality: {
    rating: Number, // 1-5
    feedback: String
  }
}, {
  timestamps: true
});

// Indexes for queries
callSchema.index({ callerId: 1, startedAt: -1 });
callSchema.index({ recipientId: 1, startedAt: -1 });
callSchema.index({ status: 1, startedAt: -1 });

module.exports = mongoose.model('Call', callSchema);












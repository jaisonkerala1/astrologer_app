/**
 * DirectMessage Model
 * Individual messages in admin-to-astrologer or user-to-astrologer conversations
 */

const mongoose = require('mongoose');

const directMessageSchema = new mongoose.Schema({
  conversationId: { 
    type: String, 
    required: true, 
    index: true 
  },
  senderId: { 
    type: String, 
    required: true,
    index: true
  },
  senderType: { 
    type: String, 
    required: true, 
    enum: ['user', 'astrologer', 'admin'] 
  },
  senderName: String,
  senderAvatar: String,
  recipientId: { 
    type: String, 
    required: true 
  },
  recipientType: { 
    type: String, 
    required: true, 
    enum: ['user', 'astrologer', 'admin'] 
  },
  content: { 
    type: String, 
    required: true 
  },
  messageType: { 
    type: String, 
    default: 'text', 
    enum: ['text', 'image', 'audio', 'video', 'file', 'location'] 
  },
  mediaUrl: String,
  mediaSize: Number,
  mediaDuration: Number, // For audio/video
  thumbnailUrl: String,
  timestamp: { 
    type: Date, 
    default: Date.now, 
    index: true 
  },
  status: { 
    type: String, 
    default: 'sent', 
    enum: ['sent', 'delivered', 'read', 'failed'] 
  },
  readAt: Date,
  deliveredAt: Date,
  replyToId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'DirectMessage'
  },
  isDeleted: {
    type: Boolean,
    default: false
  },
  deletedAt: Date
}, {
  timestamps: true
});

// Indexes for efficient queries
directMessageSchema.index({ conversationId: 1, timestamp: -1 });
directMessageSchema.index({ senderId: 1, recipientId: 1 });

module.exports = mongoose.model('DirectMessage', directMessageSchema);




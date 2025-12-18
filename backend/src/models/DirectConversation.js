/**
 * DirectConversation Model
 * For admin-to-astrologer and user-to-astrologer conversations
 */

const mongoose = require('mongoose');

const directConversationSchema = new mongoose.Schema({
  conversationId: {
    type: String,
    required: true,
    unique: true,
    index: true,
    // Format: "admin_{astrologerId}" or "user_{userId}_{astrologerId}"
  },
  participants: [{
    id: { 
      type: String, 
      required: true 
    },
    type: { 
      type: String, 
      required: true, 
      enum: ['user', 'astrologer', 'admin'] 
    },
    name: String,
    avatar: String,
  }],
  lastMessage: String,
  lastMessageAt: Date,
  lastMessageSenderId: String,
  lastMessageSenderType: String,
  unreadCount: {
    type: Map,
    of: Number,
    default: {}
  },
  isActive: {
    type: Boolean,
    default: true
  },
  createdAt: { 
    type: Date, 
    default: Date.now,
    index: true
  },
  updatedAt: { 
    type: Date, 
    default: Date.now 
  }
}, {
  timestamps: true
});

// Indexes for efficient queries
directConversationSchema.index({ 'participants.id': 1 });
directConversationSchema.index({ lastMessageAt: -1 });

module.exports = mongoose.model('DirectConversation', directConversationSchema);




const mongoose = require('mongoose');

const chatMessageSchema = new mongoose.Schema({
  id: {
    type: String,
    required: true,
  },
  content: {
    type: String,
    required: true,
  },
  isFromUser: {
    type: Boolean,
    required: true,
  },
  timestamp: {
    type: Date,
    required: true,
  },
  conversationId: {
    type: String,
    required: true,
  },
  isTyping: {
    type: Boolean,
    default: false,
  },
}, { _id: false });

const chatSettingsSchema = new mongoose.Schema({
  rememberConversations: {
    type: Boolean,
    default: true,
  },
  shareUserInfo: {
    type: Boolean,
    default: true,
  },
  preferredLanguage: {
    type: String,
    default: 'en',
  },
  notificationsEnabled: {
    type: Boolean,
    default: true,
  },
  lastCleared: {
    type: Date,
    default: Date.now,
  },
}, { _id: false });

const conversationSchema = new mongoose.Schema({
  id: {
    type: String,
    required: true,
    unique: true,
  },
  userId: {
    type: String,
    required: true,
    index: true,
  },
  title: {
    type: String,
    required: true,
    default: 'New Conversation with Loona',
  },
  messages: [chatMessageSchema],
  isActive: {
    type: Boolean,
    default: true,
  },
  chatSettings: chatSettingsSchema,
}, {
  timestamps: true,
});

// Index for efficient queries
conversationSchema.index({ userId: 1, isActive: 1 });
conversationSchema.index({ userId: 1, updatedAt: -1 });

const Conversation = mongoose.model('Conversation', conversationSchema);

module.exports = Conversation;

















































/**
 * LiveComment Model
 * Stores comments for live streams with persistence
 */

const mongoose = require('mongoose');

const liveCommentSchema = new mongoose.Schema({
  streamId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'LiveStream',
    required: true,
    index: true,
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    refPath: 'userType',
  },
  userType: {
    type: String,
    enum: ['Astrologer', 'User'],
    required: true,
  },
  userName: {
    type: String,
    required: true,
    trim: true,
  },
  userAvatar: {
    type: String,
    default: null,
  },
  message: {
    type: String,
    required: true,
    trim: true,
    maxlength: 200,
  },
  isGift: {
    type: Boolean,
    default: false,
  },
  giftType: {
    type: String,
    default: null,
  },
  giftValue: {
    type: Number,
    default: 0,
  },
}, {
  timestamps: true, // Adds createdAt and updatedAt
});

// Index for efficient querying of recent comments
liveCommentSchema.index({ streamId: 1, createdAt: -1 });

// Virtual for formatted timestamp
liveCommentSchema.virtual('timestamp').get(function() {
  return this.createdAt.getTime();
});

// Ensure virtuals are included in JSON
liveCommentSchema.set('toJSON', { virtuals: true });
liveCommentSchema.set('toObject', { virtuals: true });

// Static method to get recent comments for a stream
liveCommentSchema.statics.getRecentComments = async function(streamId, limit = 50) {
  return this.find({ streamId })
    .sort({ createdAt: -1 })
    .limit(limit)
    .lean();
};

// Clean up old comments (optional - for maintenance)
liveCommentSchema.statics.cleanupOldComments = async function(daysOld = 7) {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - daysOld);
  
  const result = await this.deleteMany({ createdAt: { $lt: cutoffDate } });
  return result.deletedCount;
};

module.exports = mongoose.model('LiveComment', liveCommentSchema);


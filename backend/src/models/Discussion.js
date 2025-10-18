const mongoose = require('mongoose');

const discussionSchema = new mongoose.Schema({
  // Author information
  authorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Astrologer',
    required: true,
    index: true
  },
  authorName: {
    type: String,
    required: true
  },
  authorPhoto: {
    type: String,
    default: null
  },
  
  // Content
  title: {
    type: String,
    required: true,
    trim: true,
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  content: {
    type: String,
    required: true,
    trim: true,
    maxlength: [5000, 'Content cannot exceed 5000 characters']
  },
  imageUrl: {
    type: String,
    default: null
  },
  
  // Categorization
  tags: [{
    type: String,
    trim: true,
    lowercase: true
  }],
  category: {
    type: String,
    enum: ['vedic', 'western', 'numerology', 'tarot', 'palmistry', 'vastu', 'general', 'other'],
    default: 'general'
  },
  
  // Engagement metrics
  likeCount: {
    type: Number,
    default: 0,
    min: 0
  },
  commentCount: {
    type: Number,
    default: 0,
    min: 0
  },
  shareCount: {
    type: Number,
    default: 0,
    min: 0
  },
  viewCount: {
    type: Number,
    default: 0,
    min: 0
  },
  saveCount: {
    type: Number,
    default: 0,
    min: 0
  },
  
  // Visibility and moderation
  isPublic: {
    type: Boolean,
    default: true
  },
  visibleTo: {
    type: String,
    enum: ['astrologers_only', 'users_only', 'both'],
    default: 'both'
  },
  isModerated: {
    type: Boolean,
    default: false
  },
  moderatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
    default: null
  },
  moderatedAt: {
    type: Date,
    default: null
  },
  moderationReason: {
    type: String,
    default: null
  },
  
  // Status
  isDeleted: {
    type: Boolean,
    default: false
  },
  deletedAt: {
    type: Date,
    default: null
  },
  
  // Analytics
  lastActivityAt: {
    type: Date,
    default: Date.now
  },
  trendingScore: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true, // Adds createdAt and updatedAt
  collection: 'discussions'
});

// Indexes for better query performance
discussionSchema.index({ authorId: 1, createdAt: -1 });
discussionSchema.index({ isPublic: 1, isDeleted: 0 });
discussionSchema.index({ visibleTo: 1 });
discussionSchema.index({ tags: 1 });
discussionSchema.index({ category: 1 });
discussionSchema.index({ trendingScore: -1, createdAt: -1 });
discussionSchema.index({ lastActivityAt: -1 });
discussionSchema.index({ createdAt: -1 });

// Text search index for title and content
discussionSchema.index({ title: 'text', content: 'text', tags: 'text' });

// Virtual for engagement rate
discussionSchema.virtual('engagementRate').get(function() {
  if (this.viewCount === 0) return 0;
  return ((this.likeCount + this.commentCount) / this.viewCount) * 100;
});

// Method to calculate trending score
discussionSchema.methods.calculateTrendingScore = function() {
  const hoursSinceCreation = (Date.now() - this.createdAt) / (1000 * 60 * 60);
  const engagement = this.likeCount + (this.commentCount * 2) + (this.shareCount * 3);
  
  // Decay score over time (gravity factor)
  const gravity = 1.8;
  this.trendingScore = engagement / Math.pow(hoursSinceCreation + 2, gravity);
  
  return this.trendingScore;
};

// Method to increment view count
discussionSchema.methods.incrementView = function() {
  this.viewCount += 1;
  this.lastActivityAt = new Date();
  return this.save();
};

// Method to increment share count
discussionSchema.methods.incrementShare = function() {
  this.shareCount += 1;
  this.lastActivityAt = new Date();
  this.calculateTrendingScore();
  return this.save();
};

// Method to update engagement counts
discussionSchema.methods.updateEngagement = async function() {
  const DiscussionLike = mongoose.model('DiscussionLike');
  const DiscussionComment = mongoose.model('DiscussionComment');
  
  this.likeCount = await DiscussionLike.countDocuments({
    targetId: this._id,
    targetType: 'discussion'
  });
  
  this.commentCount = await DiscussionComment.countDocuments({
    discussionId: this._id,
    isDeleted: false
  });
  
  this.lastActivityAt = new Date();
  this.calculateTrendingScore();
  
  return this.save();
};

// Soft delete method
discussionSchema.methods.softDelete = function() {
  this.isDeleted = true;
  this.deletedAt = new Date();
  return this.save();
};

// Ensure virtual fields are serialized
discussionSchema.set('toJSON', { virtuals: true });
discussionSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Discussion', discussionSchema);


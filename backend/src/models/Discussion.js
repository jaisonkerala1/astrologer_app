const mongoose = require('mongoose');

/**
 * Discussion Model
 * Represents a discussion post created by an astrologer
 * Supports real-time updates via Socket.IO
 */
const discussionSchema = new mongoose.Schema({
  // Author reference
  authorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Astrologer',
    required: true,
    index: true
  },
  authorName: {
    type: String,
    required: true,
    trim: true
  },
  authorAvatar: {
    type: String,
    default: null
  },

  // Content
  title: {
    type: String,
    required: [true, 'Title is required'],
    trim: true,
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  content: {
    type: String,
    required: [true, 'Content is required'],
    trim: true,
    maxlength: [5000, 'Content cannot exceed 5000 characters']
  },
  category: {
    type: String,
    required: true,
    trim: true,
    enum: [
      'Astrology & Horoscopes',
      'Yoga, Meditation & Mindfulness',
      'Healing & Wellness',
      'Spiritual Growth & Practices',
      'Vedic Rituals & Puja',
      'Vastu & Feng Shui',
      'Tarot & Divination',
      'Numerology & Palmistry',
      'Community Support & Life Talk',
      'General Discussion'
    ],
    default: 'General Discussion'
  },

  // Engagement metrics
  likes: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Astrologer'
  }],
  likesCount: {
    type: Number,
    default: 0
  },
  commentsCount: {
    type: Number,
    default: 0
  },

  // Visibility & Status
  visibility: {
    type: String,
    enum: ['public', 'subscribers', 'private'],
    default: 'public'
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isPinned: {
    type: Boolean,
    default: false
  },

  // Media attachments (future use)
  attachments: [{
    type: {
      type: String,
      enum: ['image', 'video', 'link']
    },
    url: String,
    thumbnail: String
  }],

  // Tags for search
  tags: [{
    type: String,
    trim: true,
    lowercase: true
  }]
}, {
  timestamps: true
});

// Indexes for efficient queries
discussionSchema.index({ createdAt: -1 });
discussionSchema.index({ category: 1, createdAt: -1 });
discussionSchema.index({ authorId: 1, createdAt: -1 });
discussionSchema.index({ visibility: 1, isActive: 1, createdAt: -1 });
discussionSchema.index({ tags: 1 });
discussionSchema.index({ likesCount: -1 }); // For trending
discussionSchema.index({ commentsCount: -1 }); // For popular

// Virtual for author's initial
discussionSchema.virtual('authorInitial').get(function() {
  return this.authorName ? this.authorName.charAt(0).toUpperCase() : '?';
});

// Method to toggle like
discussionSchema.methods.toggleLike = async function(userId) {
  const userIdStr = userId.toString();
  const likeIndex = this.likes.findIndex(id => id.toString() === userIdStr);
  
  if (likeIndex > -1) {
    // Unlike
    this.likes.splice(likeIndex, 1);
    this.likesCount = Math.max(0, this.likesCount - 1);
  } else {
    // Like
    this.likes.push(userId);
    this.likesCount = this.likes.length;
  }
  
  await this.save();
  return likeIndex === -1; // Returns true if liked, false if unliked
};

// Method to check if user liked
discussionSchema.methods.isLikedBy = function(userId) {
  if (!userId) return false;
  return this.likes.some(id => id.toString() === userId.toString());
};

// Method to increment comment count
discussionSchema.methods.incrementCommentCount = async function() {
  this.commentsCount += 1;
  return this.save();
};

// Method to decrement comment count
discussionSchema.methods.decrementCommentCount = async function() {
  this.commentsCount = Math.max(0, this.commentsCount - 1);
  return this.save();
};

// Static method to get discussions with pagination
discussionSchema.statics.getPaginated = async function(options = {}) {
  const {
    page = 1,
    limit = 20,
    category = null,
    authorId = null,
    visibility = 'public',
    sortBy = 'createdAt',
    sortOrder = -1,
    userId = null // For checking if liked by user
  } = options;

  const query = { isActive: true };
  
  if (category) query.category = category;
  if (authorId) query.authorId = authorId;
  if (visibility) query.visibility = visibility;

  const skip = (page - 1) * limit;
  const sort = { [sortBy]: sortOrder };

  const [discussions, total] = await Promise.all([
    this.find(query)
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .lean(),
    this.countDocuments(query)
  ]);

  // Add isLiked field for each discussion
  const discussionsWithLiked = discussions.map(d => ({
    ...d,
    isLiked: userId ? d.likes?.some(id => id.toString() === userId.toString()) : false,
    likes: undefined // Remove likes array from response (only send count)
  }));

  return {
    discussions: discussionsWithLiked,
    pagination: {
      page,
      limit,
      total,
      pages: Math.ceil(total / limit),
      hasMore: page * limit < total
    }
  };
};

// Ensure virtuals are included in JSON
discussionSchema.set('toJSON', { virtuals: true });
discussionSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Discussion', discussionSchema);

